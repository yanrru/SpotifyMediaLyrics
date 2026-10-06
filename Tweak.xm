#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <objc/runtime.h>

static void DumpObjectProperties(id obj)
{
    if (!obj) return;

    Class cls = object_getClass(obj);

    NSLog(@"[SpotifyMediaLyrics] ===== LYRICS OBJECT =====");
    NSLog(@"[SpotifyMediaLyrics] class = %@", NSStringFromClass(cls));
    NSLog(@"[SpotifyMediaLyrics] object = %@", obj);

    unsigned int count = 0;
    objc_property_t *properties = class_copyPropertyList(cls, &count);

    for (unsigned int i = 0; i < count; i++) {
        const char *name = property_getName(properties[i]);
        if (name) {
            NSLog(@"[SpotifyMediaLyrics] property = %s", name);
        }
    }

    free(properties);

    count = 0;
    Method *methods = class_copyMethodList(cls, &count);

    for (unsigned int i = 0; i < count; i++) {
        SEL sel = method_getName(methods[i]);
        if (sel) {
            NSLog(@"[SpotifyMediaLyrics] method = %@",
                  NSStringFromSelector(sel));
        }
    }

    free(methods);
}

static void ScanEevee(void)
{
    int count = objc_getClassList(NULL, 0);
    if (count <= 0) return;

    Class *classes =
        (__unsafe_unretained Class *)malloc(sizeof(Class) * count);

    count = objc_getClassList(classes, count);

    for (int i = 0; i < count; i++) {
        Class cls = classes[i];
        const char *name = class_getName(cls);

        if (!name) continue;

        if (strstr(name, "LyricsData") ||
            strstr(name, "LyricsLine") ||
            strstr(name, "KaraokeLyricsStore")) {

            NSLog(@"[SpotifyMediaLyrics] FOUND %@", NSStringFromClass(cls));

            unsigned int methodCount = 0;
            Method *methods = class_copyMethodList(cls, &methodCount);

            for (unsigned int j = 0; j < methodCount; j++) {
                SEL sel = method_getName(methods[j]);

                NSLog(@"[SpotifyMediaLyrics] %@ -> %@",
                      NSStringFromClass(cls),
                      NSStringFromSelector(sel));
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
        NSLog(@"[SpotifyMediaLyrics] lyrics bridge loaded");

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
