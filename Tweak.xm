#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static void ScanTargetClasses(void)
{
    const char *targets[] = {
        "LyricsData",
        "LyricsLine",
        "KaraokeLyricsStore",
        "LyricsRepository"
    };

    NSLog(@"[SpotifyMediaLyrics] ===== TARGET SCAN =====");

    for (int i = 0; i < 4; i++) {

        Class cls = objc_getClass(targets[i]);

        if (!cls) {
            NSLog(@"[SpotifyMediaLyrics] NOT FOUND: %s", targets[i]);
            continue;
        }

        NSLog(@"[SpotifyMediaLyrics] FOUND: %s", targets[i]);

        unsigned int count = 0;
        Method *methods = class_copyMethodList(cls, &count);

        for (unsigned int j = 0; j < count; j++) {
            SEL sel = method_getName(methods[j]);

            if (sel) {
                const char *name = sel_getName(sel);

                if (name) {
                    NSLog(@"[SpotifyMediaLyrics] %s -> %s",
                          targets[i],
                          name);
                }
            }
        }

        free(methods);
    }
}

__attribute__((constructor))
static void SpotifyMediaLyricsInit(void)
{
    NSLog(@"[SpotifyMediaLyrics] LOADED");

    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW,
                      (int64_t)(5 * NSEC_PER_SEC)),
        dispatch_get_main_queue(),
        ^{
            ScanTargetClasses();
        }
    );
}
