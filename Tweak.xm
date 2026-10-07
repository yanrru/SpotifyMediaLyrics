#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#pragma mark - Safe Class Probe

static void DumpClassMethods(const char *className)
{
    Class cls = objc_getClass(className);

    if (!cls) {
        NSLog(@"[SpotifyMediaLyrics] CLASS NOT FOUND: %s", className);
        return;
    }

    NSLog(@"[SpotifyMediaLyrics] ========================================");
    NSLog(@"[SpotifyMediaLyrics] FOUND CLASS: %s", className);

    Class superCls = class_getSuperclass(cls);

    if (superCls) {
        const char *superName = class_getName(superCls);

        if (superName) {
            NSLog(@"[SpotifyMediaLyrics] SUPERCLASS: %s", superName);
        }
    }

    unsigned int count = 0;
    Method *methods = class_copyMethodList(cls, &count);

    if (!methods) {
        NSLog(@"[SpotifyMediaLyrics] NO DIRECT METHODS: %s", className);
        return;
    }

    NSLog(@"[SpotifyMediaLyrics] DIRECT METHOD COUNT: %u", count);

    for (unsigned int i = 0; i < count; i++) {

        SEL selector = method_getName(methods[i]);

        if (!selector) {
            continue;
        }

        const char *methodName = sel_getName(selector);

        if (!methodName) {
            continue;
        }

        const char *typeEncoding = method_getTypeEncoding(methods[i]);

        if (typeEncoding) {
            NSLog(@"[SpotifyMediaLyrics] METHOD: %s | TYPES: %s",
                  methodName,
                  typeEncoding);
        } else {
            NSLog(@"[SpotifyMediaLyrics] METHOD: %s",
                  methodName);
        }
    }

    free(methods);

    NSLog(@"[SpotifyMediaLyrics] ========================================");
}


#pragma mark - Target Classes

static void ScanSpotifyLyricsClasses(void)
{
    NSLog(@"[SpotifyMediaLyrics] ");
    NSLog(@"[SpotifyMediaLyrics] ****************************************");
    NSLog(@"[SpotifyMediaLyrics] SPOTIFY 9.1.88 LYRICS PROBE START");
    NSLog(@"[SpotifyMediaLyrics] ****************************************");

    /*
     * Spotify 9.1.88
     *
     * These are the actual Swift classes found inside
     * the current Spotify binary.
     */

    DumpClassMethods(
        "_TtC17Canvas_CommonImpl29CanvasNowPlayingLyricsManager"
    );

    DumpClassMethods(
        "_TtC17Canvas_CommonImpl26CanvasNowPlayingLyricsView"
    );

    DumpClassMethods(
        "_TtC17Canvas_CommonImpl33CanvasNowPlayingLyricsElementView"
    );

    DumpClassMethods(
        "_TtC24Lyrics_TextComponentImpl34LyricsViewControllerImplementation"
    );

    DumpClassMethods(
        "_TtC24Lyrics_TextComponentImpl10LyricsView"
    );

    DumpClassMethods(
        "_TtC27Lyrics_RemoteDataSourceImpl20LyricsDataLoaderImpl"
    );

    NSLog(@"[SpotifyMediaLyrics] ****************************************");
    NSLog(@"[SpotifyMediaLyrics] SPOTIFY 9.1.88 LYRICS PROBE END");
    NSLog(@"[SpotifyMediaLyrics] ****************************************");
}


#pragma mark - Plugin Entry

__attribute__((constructor))
static void SpotifyMediaLyricsInit(void)
{
    NSLog(@"[SpotifyMediaLyrics] ========================================");
    NSLog(@"[SpotifyMediaLyrics] LOADED");
    NSLog(@"[SpotifyMediaLyrics] Build: SafeLyricsProbe-9.1.88");
    NSLog(@"[SpotifyMediaLyrics] ========================================");

    /*
     * Do not inspect the runtime immediately.
     *
     * Wait until Spotify has finished loading its components.
     */
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            (int64_t)(8 * NSEC_PER_SEC)
        ),
        dispatch_get_main_queue(),
        ^{
            ScanSpotifyLyricsClasses();
        }
    );
}
