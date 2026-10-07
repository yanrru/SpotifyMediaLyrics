#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <objc/runtime.h>

static IMP SMLOriginalSetNowPlayingInfo = NULL;

static NSString *SMLFindMethods(Class cls)
{
    if (!cls) {
        return nil;
    }

    NSMutableArray *result =
        [NSMutableArray array];

    unsigned int count = 0;

    Method *methods =
        class_copyMethodList(cls, &count);

    if (!methods) {
        return nil;
    }

    for (unsigned int i = 0; i < count; i++) {

        SEL sel =
            method_getName(methods[i]);

        if (!sel) {
            continue;
        }

        const char *name =
            sel_getName(sel);

        if (!name) {
            continue;
        }

        NSString *methodName =
            [NSString stringWithUTF8String:name];

        NSString *lower =
            methodName.lowercaseString;

        /*
         * 只记录与歌词/当前行有关的方法。
         */
        if (
            [lower containsString:@"lyric"] ||
            [lower containsString:@"line"] ||
            [lower containsString:@"active"] ||
            [lower containsString:@"current"] ||
            [lower containsString:@"change"]
        ) {

            [result addObject:methodName];

            /*
             * 锁屏标题空间有限。
             * 找到几个就够了。
             */
            if (result.count >= 8) {
                break;
            }
        }
    }

    free(methods);

    if (result.count == 0) {
        return @"NO_METHOD";
    }

    return [result componentsJoinedByString:@","];
}

static NSString *SMLProbeLyricsClasses(void)
{
    NSArray *classes = @[
        @"_TtC17Canvas_CommonImpl29CanvasNowPlayingLyricsManager",
        @"_TtC17Canvas_CommonImpl26CanvasNowPlayingLyricsView",
        @"_TtC17Canvas_CommonImpl33CanvasNowPlayingLyricsElementView",
        @"_TtC32Lyrics_FullscreenElementPageImpl10LyricsView",
        @"_TtC24Lyrics_TextComponentImpl34LyricsViewControllerImplementation",
        @"_TtC24Lyrics_TextComponentImpl10LyricsView",
        @"_TtC27Lyrics_RemoteDataSourceImpl20LyricsDataLoaderImpl"
    ];

    NSMutableArray *found =
        [NSMutableArray array];

    for (NSString *name in classes) {

        Class cls =
            objc_getClass(name.UTF8String);

        if (!cls) {
            continue;
        }

        NSString *methods =
            SMLFindMethods(cls);

        NSString *shortName = nil;

        if ([name containsString:@"LyricsManager"]) {
            shortName = @"MGR";
        }
        else if ([name containsString:@"LyricsElementView"]) {
            shortName = @"ELEMENT";
        }
        else if ([name containsString:@"NowPlayingLyricsView"]) {
            shortName = @"NPVIEW";
        }
        else if ([name containsString:@"LyricsViewController"]) {
            shortName = @"VC";
        }
        else if ([name containsString:@"LyricsView"]) {
            shortName = @"VIEW";
        }
        else if ([name containsString:@"LyricsDataLoader"]) {
            shortName = @"LOADER";
        }
        else {
            shortName = @"OTHER";
        }

        NSString *entry =
            [NSString stringWithFormat:
                @"%@=%@",
                shortName,
                methods ?: @"NO_METHOD"];

        [found addObject:entry];
    }

    if (found.count == 0) {
        return @"NO_LYRICS_CLASSES";
    }

    return [found componentsJoinedByString:@"|"];
}

static void SMLHookedSetNowPlayingInfo(
    MPNowPlayingInfoCenter *self,
    SEL _cmd,
    NSDictionary *info
)
{
    if (!SMLOriginalSetNowPlayingInfo) {
        return;
    }

    NSMutableDictionary *newInfo =
        info
        ? [info mutableCopy]
        : [NSMutableDictionary dictionary];

    static NSString *probeResult = nil;
    static BOOL didProbe = NO;

    if (!didProbe) {

        didProbe = YES;

        probeResult =
            SMLProbeLyricsClasses();

        NSLog(
            @"[SpotifyMediaLyrics] LYRICS PROBE: %@",
            probeResult
        );
    }

    NSString *title =
        newInfo[MPMediaItemPropertyTitle];

    if (!title) {
        title = @"";
    }

    NSString *displayTitle =
        [NSString stringWithFormat:
            @"[SML:%@] %@",
            probeResult ?: @"UNKNOWN",
            title];

    /*
     * 防止标题无限叠加。
     */
    if (![title hasPrefix:@"[SML:"]) {
        newInfo[MPMediaItemPropertyTitle] =
            displayTitle;
    }

    ((void (*)(id, SEL, NSDictionary *))
        SMLOriginalSetNowPlayingInfo)(
            self,
            _cmd,
            newInfo
    );
}

__attribute__((constructor))
static void SpotifyMediaLyricsInit(void)
{
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            (int64_t)(3 * NSEC_PER_SEC)
        ),
        dispatch_get_main_queue(),
        ^{
            Class cls =
                objc_getClass(
                    "MPNowPlayingInfoCenter"
                );

            if (!cls) {
                return;
            }

            SEL selector =
                @selector(setNowPlayingInfo:);

            Method method =
                class_getInstanceMethod(
                    cls,
                    selector
                );

            if (!method) {
                return;
            }

            SMLOriginalSetNowPlayingInfo =
                method_getImplementation(method);

            if (!SMLOriginalSetNowPlayingInfo) {
                return;
            }

            method_setImplementation(
                method,
                (IMP)SMLHookedSetNowPlayingInfo
            );
        }
    );
}
