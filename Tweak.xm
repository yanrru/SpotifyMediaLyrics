#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static NSString *SMLLogPath(void)
{
    NSArray *paths =
        NSSearchPathForDirectoriesInDomains(
            NSDocumentDirectory,
            NSUserDomainMask,
            YES
        );

    NSString *documents = paths.firstObject;

    if (!documents) {
        return @"/tmp/SpotifyMediaLyrics_runtime.log";
    }

    return [documents stringByAppendingPathComponent:
            @"SpotifyMediaLyrics_runtime.log"];
}

static void SMLWrite(NSString *text)
{
    NSString *line =
        [NSString stringWithFormat:@"%@\n", text];

    NSLog(@"[SpotifyMediaLyrics] %@", text);

    NSString *path = SMLLogPath();

    NSFileHandle *handle =
        [NSFileHandle fileHandleForWritingAtPath:path];

    if (!handle) {
        [line writeToFile:path
              atomically:YES
                encoding:NSUTF8StringEncoding
                   error:nil];
        return;
    }

    [handle seekToEndOfFile];

    [handle writeData:
        [line dataUsingEncoding:NSUTF8StringEncoding]];

    [handle closeFile];
}

static void ProbeClass(const char *name)
{
    if (!name) {
        return;
    }

    Class cls = objc_getClass(name);

    if (!cls) {
        SMLWrite(
            [NSString stringWithFormat:
                @"NOT FOUND: %s",
                name]
        );
        return;
    }

    SMLWrite(
        [NSString stringWithFormat:
            @"FOUND CLASS: %s",
            class_getName(cls)]
    );

    Class superClass = class_getSuperclass(cls);

    if (superClass) {
        SMLWrite(
            [NSString stringWithFormat:
                @"SUPER: %s",
                class_getName(superClass)]
        );
    }

    unsigned int count = 0;

    Method *methods =
        class_copyMethodList(cls, &count);

    if (!methods) {
        SMLWrite(
            [NSString stringWithFormat:
                @"NO DIRECT METHODS: %s",
                class_getName(cls)]
        );
        return;
    }

    SMLWrite(
        [NSString stringWithFormat:
            @"METHOD COUNT: %u",
            count]
    );

    for (unsigned int i = 0; i < count; i++) {

        Method method = methods[i];

        if (!method) {
            continue;
        }

        SEL selector = method_getName(method);

        if (!selector) {
            continue;
        }

        const char *selectorName =
            sel_getName(selector);

        if (!selectorName) {
            continue;
        }

        const char *types =
            method_getTypeEncoding(method);

        if (types) {

            SMLWrite(
                [NSString stringWithFormat:
                    @"METHOD: %s | TYPES: %s",
                    selectorName,
                    types]
            );

        } else {

            SMLWrite(
                [NSString stringWithFormat:
                    @"METHOD: %s",
                    selectorName]
            );
        }
    }

    free(methods);
}

static void RunProbe(void)
{
    SMLWrite(@"========================================");
    SMLWrite(@"RUNTIME PROBE START");
    SMLWrite(@"========================================");

    ProbeClass(
        "_TtC17Canvas_CommonImpl29CanvasNowPlayingLyricsManager"
    );

    ProbeClass(
        "_TtC17Canvas_CommonImpl26CanvasNowPlayingLyricsView"
    );

    ProbeClass(
        "_TtC17Canvas_CommonImpl33CanvasNowPlayingLyricsElementView"
    );

    ProbeClass(
        "_TtC24Lyrics_TextComponentImpl34LyricsViewControllerImplementation"
    );

    ProbeClass(
        "_TtC24Lyrics_TextComponentImpl10LyricsView"
    );

    ProbeClass(
        "_TtC27Lyrics_RemoteDataSourceImpl20LyricsDataLoaderImpl"
    );

    SMLWrite(@"========================================");
    SMLWrite(@"RUNTIME PROBE END");
    SMLWrite(@"========================================");
}

__attribute__((constructor))
static void SpotifyMediaLyricsInit(void)
{
    SMLWrite(@"");
    SMLWrite(@"########################################");
    SMLWrite(@"SpotifyMediaLyrics LOADED");
    SMLWrite(@"########################################");

    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            (int64_t)(8 * NSEC_PER_SEC)
        ),
        dispatch_get_main_queue(),
        ^{
            RunProbe();
        }
    );
}
