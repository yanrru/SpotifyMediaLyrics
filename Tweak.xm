#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

#pragma mark - Logging

static void SMLLog(NSString *format, ...)
{
    va_list args;
    va_start(args, format);

    NSString *message =
        [[NSString alloc] initWithFormat:format arguments:args];

    va_end(args);

    NSLog(@"[SpotifyMediaLyrics] %@", message);
}

#pragma mark - Class Probe

static void DumpMethods(Class cls)
{
    if (!cls) {
        return;
    }

    const char *className = class_getName(cls);

    if (!className) {
        return;
    }

    SMLLog(@"FOUND CLASS: %s", className);

    Class superClass = class_getSuperclass(cls);

    if (superClass) {
        const char *superName = class_getName(superClass);

        if (superName) {
            SMLLog(@"SUPERCLASS: %s", superName);
        }
    }

    unsigned int count = 0;

    Method *methods = class_copyMethodList(cls, &count);

    if (!methods) {
        SMLLog(@"NO DIRECT METHODS: %s", className);
        return;
    }

    SMLLog(@"METHOD COUNT: %u", count);

    for (unsigned int i = 0; i < count; i++) {

        Method method = methods[i];

        if (!method) {
            continue;
        }

        SEL selector = method_getName(method);

        if (!selector) {
            continue;
        }

        const char *selectorName = sel_getName(selector);

        if (!selectorName) {
            continue;
        }

        const char *types = method_getTypeEncoding(method);

        if (types) {
            SMLLog(@"METHOD: %s | TYPES: %s",
                   selectorName,
                   types);
        } else {
            SMLLog(@"METHOD: %s",
                   selectorName);
        }
    }

    free(methods);
}

#pragma mark - Target Search

static void ProbeClass(const char *name)
{
    if (!name) {
        return;
    }

    Class cls = objc_getClass(name);

    if (!cls) {
        SMLLog(@"NOT FOUND: %s", name);
        return;
    }

    DumpMethods(cls);
}

static void RunProbe(void)
{
    SMLLog(@"========================================");
    SMLLog(@"SPOTIFY MEDIA LYRICS PROBE START");
    SMLLog(@"========================================");

    /*
     * Spotify 9.1.88
     */

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

    SMLLog(@"========================================");
    SMLLog(@"SPOTIFY MEDIA LYRICS PROBE END");
    SMLLog(@"========================================");
}

#pragma mark - Constructor

__attribute__((constructor))
static void SpotifyMediaLyricsInit(void)
{
    /*
     * This message must appear if the dylib is actually loaded.
     */
    SMLLog(@"========================================");
    SMLLog(@"LOADED");
    SMLLog(@"SpotifyMediaLyrics Safe Probe");
    SMLLog(@"========================================");

    /*
     * Wait for Spotify frameworks/components to finish loading.
     */
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            (int64_t)(10 * NSEC_PER_SEC)
        ),
        dispatch_get_main_queue(),
        ^{
            SMLLog(@"Starting delayed probe...");
            RunProbe();
        }
    );
}
