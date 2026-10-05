#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <objc/runtime.h>

static void DumpClassInfo(Class cls) {
    if (!cls) return;

    NSLog(@"[SpotifyMediaLyrics] ===== CLASS %@ =====", NSStringFromClass(cls));

    unsigned int count = 0;

    Method *methods = class_copyMethodList(cls, &count);
    for (unsigned int i = 0; i < count; i++) {
        Method m = methods[i];
        SEL sel = method_getName(m);
        const char *types = method_getTypeEncoding(m);

        NSLog(@"[SpotifyMediaLyrics] method: %@  types: %s",
              NSStringFromSelector(sel), types ?: "");
    }
    free(methods);

    Class meta = object_getClass(cls);
    if (meta) {
        count = 0;
        Method *classMethods = class_copyMethodList(meta, &count);

        for (unsigned int i = 0; i < count; i++) {
            Method m = classMethods[i];
            SEL sel = method_getName(m);
            const char *types = method_getTypeEncoding(m);

            NSLog(@"[SpotifyMediaLyrics] class method: %@  types: %s",
                  NSStringFromSelector(sel), types ?: "");
        }

        free(classMethods);
    }
}

static void DumpEeveeClasses(void) {
    int count = objc_getClassList(NULL, 0);
    if (count <= 0) return;

    Class *classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * count);
    count = objc_getClassList(classes, count);

    NSLog(@"[SpotifyMediaLyrics] ===== Eevee runtime scan =====");

    for (int i = 0; i < count; i++) {
        Class cls = classes[i];
        const char *name = class_getName(cls);

        if (!name) continue;

        if (strstr(name, "Eevee") ||
            strstr(name, "Karaoke") ||
            strstr(name, "Lyrics")) {

            NSLog(@"[SpotifyMediaLyrics] FOUND CLASS: %s", name);

            if (strstr(name, "KaraokeLyricsStore") ||
                strstr(name, "LyricsData") ||
                strstr(name, "LyricsLine")) {
                DumpClassInfo(cls);
            }
        }
    }

    free(classes);
}

static void LyricsChangedNotification(NSNotification *note) {
    NSLog(@"[SpotifyMediaLyrics] ===== LYRICS CHANGED =====");
    NSLog(@"[SpotifyMediaLyrics] notification name: %@", note.name);
    NSLog(@"[SpotifyMediaLyrics] object class: %@",
          note.object ? NSStringFromClass([note.object class]) : @"<nil>");
    NSLog(@"[SpotifyMediaLyrics] object: %@", note.object);
    NSLog(@"[SpotifyMediaLyrics] userInfo: %@", note.userInfo);

    if ([note.object respondsToSelector:@selector(description)]) {
        NSLog(@"[SpotifyMediaLyrics] object description: %@",
              [note.object description]);
    }
}

__attribute__((constructor))
static void SpotifyMediaLyricsInit(void) {
    @autoreleasepool {
        NSLog(@"[SpotifyMediaLyrics] ===== START =====");
        NSLog(@"[SpotifyMediaLyrics] SpotifyMediaLyrics 9.1.88 probe loaded");

        [[NSNotificationCenter defaultCenter]
            addObserverForName:@"EeveeKaraokeLyricsChanged"
                        object:nil
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(NSNotification *note) {
                        LyricsChangedNotification(note);
                    }];

        dispatch_after(
            dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)),
            dispatch_get_main_queue(),
            ^{
                DumpEeveeClasses();
            }
        );
    }
}
