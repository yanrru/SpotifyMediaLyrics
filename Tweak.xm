#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <objc/runtime.h>
#import <objc/message.h>

static IMP SMLOriginalSetNowPlayingInfo = NULL;

#pragma mark - Private Now Playing Content Item

static id SMLGetContentItem(void)
{
    MPNowPlayingInfoCenter *center =
        [MPNowPlayingInfoCenter defaultCenter];

    SEL selector =
        NSSelectorFromString(@"nowPlayingContentItem");

    if (![center respondsToSelector:selector]) {
        NSLog(@"[SpotifyMediaLyrics] nowPlayingContentItem NOT AVAILABLE");
        return nil;
    }

    id (*Getter)(id, SEL) =
        (id (*)(id, SEL))objc_msgSend;

    id item = Getter(center, selector);

    if (!item) {
        NSLog(@"[SpotifyMediaLyrics] ContentItem = NIL");
        return nil;
    }

    NSLog(
        @"[SpotifyMediaLyrics] ContentItem FOUND: %s",
        class_getName(object_getClass(item))
    );

    return item;
}

static void SMLTestContentItem(void)
{
    id item = SMLGetContentItem();

    if (!item) {
        return;
    }

    SEL titleSelector =
        NSSelectorFromString(@"title");

    SEL setTitleSelector =
        NSSelectorFromString(@"setTitle:");

    NSString *oldTitle = nil;

    if ([item respondsToSelector:titleSelector]) {

        id (*GetTitle)(id, SEL) =
            (id (*)(id, SEL))objc_msgSend;

        oldTitle =
            GetTitle(item, titleSelector);

        NSLog(
            @"[SpotifyMediaLyrics] ContentItem title = %@",
            oldTitle
        );
    }

    if ([item respondsToSelector:setTitleSelector]) {

        void (*SetTitle)(id, SEL, id) =
            (void (*)(id, SEL, id))objc_msgSend;

        NSString *testTitle =
            [NSString stringWithFormat:
                @"[SML ITEM] %@",
                oldTitle ?: @"TEST"];

        SetTitle(
            item,
            setTitleSelector,
            testTitle
        );

        NSLog(
            @"[SpotifyMediaLyrics] ContentItem title SET: %@",
            testTitle
        );
    } else {

        NSLog(
            @"[SpotifyMediaLyrics] ContentItem setTitle: NOT FOUND"
        );
    }
}

#pragma mark - Now Playing Hook

static void SMLHookedSetNowPlayingInfo(
    MPNowPlayingInfoCenter *self,
    SEL _cmd,
    NSDictionary *info
)
{
    if (SMLOriginalSetNowPlayingInfo) {

        ((void (*)(id, SEL, NSDictionary *))
            SMLOriginalSetNowPlayingInfo)(
                self,
                _cmd,
                info
        );
    }

    /*
     * Spotify 写入 Now Playing 后，
     * 尝试取得私有 MPNowPlayingContentItem。
     */
    SMLTestContentItem();
}

#pragma mark - Init

__attribute__((constructor))
static void SpotifyMediaLyricsInit(void)
{
    NSLog(
        @"[SpotifyMediaLyrics] PRIVATE CONTENT ITEM TEST LOADED"
    );

    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            (int64_t)(3 * NSEC_PER_SEC)
        ),
        dispatch_get_main_queue(),
        ^{
            Class cls =
                objc_getClass("MPNowPlayingInfoCenter");

            if (!cls) {
                NSLog(
                    @"[SpotifyMediaLyrics] MPNowPlayingInfoCenter NOT FOUND"
                );
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
                NSLog(
                    @"[SpotifyMediaLyrics] setNowPlayingInfo NOT FOUND"
                );
                return;
            }

            SMLOriginalSetNowPlayingInfo =
                method_getImplementation(method);

            if (!SMLOriginalSetNowPlayingInfo) {
                NSLog(
                    @"[SpotifyMediaLyrics] ORIGINAL IMP NOT FOUND"
                );
                return;
            }

            method_setImplementation(
                method,
                (IMP)SMLHookedSetNowPlayingInfo
            );

            NSLog(
                @"[SpotifyMediaLyrics] NOW PLAYING HOOK READY"
            );
        }
    );
}
