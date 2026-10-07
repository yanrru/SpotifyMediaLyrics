#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <objc/runtime.h>
#import <objc/message.h>

static void SMLHookedSetNowPlayingInfo(
    MPNowPlayingInfoCenter *self,
    SEL _cmd,
    NSDictionary *info
)
{
    NSMutableDictionary *newInfo =
        [info mutableCopy];

    if (!newInfo) {
        newInfo = [NSMutableDictionary dictionary];
    }

    NSString *title =
        newInfo[MPMediaItemPropertyTitle];

    if (!title) {
        title = @"";
    }

    NSString *artist =
        newInfo[MPMediaItemPropertyArtist];

    if (!artist) {
        artist = @"";
    }

    NSString *newTitle =
        [NSString stringWithFormat:
            @"[SML HOOK] %@",
            title];

    newInfo[MPMediaItemPropertyTitle] = newTitle;

    NSLog(
        @"[SpotifyMediaLyrics] NOW PLAYING: %@ - %@",
        artist,
        title
    );

    ((void (*)(id, SEL, NSDictionary *))objc_msgSend)(
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

            method_setImplementation(
                method,
                (IMP)SMLHookedSetNowPlayingInfo
            );

            NSLog(
                @"[SpotifyMediaLyrics] MPNowPlayingInfoCenter HOOKED"
            );
        }
    );
}
