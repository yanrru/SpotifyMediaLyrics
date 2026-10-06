#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static void ScanEevee(void)
{
    int count = objc_getClassList(NULL, 0);
    if (count <= 0) return;

    Class *classes =
        (__unsafe_unretained Class *)malloc(sizeof(Class) * count);

    count = objc_getClassList(classes, count);

    NSLog(@"[SpotifyMediaLyrics] ===== Eevee runtime scan =====");

    for (int i = 0; i < count; i++) {
        Class cls = classes[i];
        const char *name = class_getName(cls);

        if (!name) continue;

        if (strstr(name, "LyricsData") ||
            strstr(name, "LyricsLine") ||
            strstr(name, "KaraokeLyricsStore") ||
            strstr(name, "LyricsRepository")) {

            NSLog(@"[SpotifyMediaLyrics] FOUND CLASS: %s", name);

            unsigned int methodCount = 0;
            Method *methods = class_copyMethodList(cls, &methodCount);

            for (unsigned int j = 0; j < methodCount; j++) {
                SEL sel = method_getName(methods[j]);

                if (sel) {
                    NSLog(@"[SpotifyMediaLyrics] %@ -> %@",
                          NSStringFromClass(cls),
                          NSStringFromSelector(sel));
                }
            }

            free(methods);
        }
    }

    free(classes);
}

__attribute__((constructor))
static void SpotifyMediaLyricsInit(void)
{
    @autoreleasepool {

        NSLog(@"[SpotifyMediaLyrics] ===== START =====");
        NSLog(@"[SpotifyMediaLyrics] lyrics bridge probe loaded");

        dispatch_after(
            dispatch_time(DISPATCH_TIME_NOW,
                          (int64_t)(8 * NSEC_PER_SEC)),
            dispatch_get_main_queue(),
            ^{
                ScanEevee();
            }
        );
    }
}
