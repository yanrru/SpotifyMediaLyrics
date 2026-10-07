#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <objc/runtime.h>
#import <objc/message.h>

static IMP SMLOriginalSetNowPlayingInfo = NULL;

static void SMLHookedSetNowPlayingInfo(
    MPNowPlayingInfoCenter *self,
    SEL _cmd,
    NSDictionary *info
)
{
    NSMutableDictionary *newInfo =
        info ? [info mutableCopy]
             : [NSMutableDictionary dictionary];

    NSString *title =
        newInfo[MPMediaItemPropertyTitle];

    if (!title) {
        title = @"";
    }

    /*
     * 测试：
     * 只在还没有 [SML HOOK] 的情况下添加。
     * 防止 Spotify 自己重复调用时不断叠加。
     */
    if (![title hasPrefix:@"[SML HOOK]"]) {

        newInfo[MPMediaItemPropertyTitle] =
            [NSString stringWithFormat:
                @"[SML HOOK] %@",
                title];
    }

    /*
     * 关键：
     * 调用原始 IMP，而不是 objc_msgSend。
     * 否则会递归调用自己导致崩溃。
     */
    if (SMLOriginalSetNowPlayingInfo) {

        ((void (*)(id, SEL, NSDictionary *))
            SMLOriginalSetNowPlayingInfo)(
                self,
                _cmd,
                newInfo
        );
    }
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
