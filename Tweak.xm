#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>

__attribute__((constructor))
static void SpotifyMediaLyricsInit(void)
{
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            (int64_t)(5 * NSEC_PER_SEC)
        ),
        dispatch_get_main_queue(),
        ^{
            MPNowPlayingInfoCenter *center =
                [MPNowPlayingInfoCenter defaultCenter];

            NSMutableDictionary *info =
                [center.nowPlayingInfo mutableCopy];

            if (!info) {
                info = [NSMutableDictionary dictionary];
            }

            NSString *oldTitle =
                info[MPMediaItemPropertyTitle];

            if (!oldTitle) {
                oldTitle = @"";
            }

            info[MPMediaItemPropertyTitle] =
                [NSString stringWithFormat:
                    @"[SML TEST] %@",
                    oldTitle];

            [center setNowPlayingInfo:info];
        }
    );
}
