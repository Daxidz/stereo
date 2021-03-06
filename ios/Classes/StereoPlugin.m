#import <AVFoundation/AVFoundation.h>
#import <Flutter/Flutter.h>
#import <MediaPlayer/MediaPlayer.h>

#import "MCMediaPickerController.h"
#import "StereoPlugin.h"

@implementation StereoPlugin {
    FlutterMethodChannel *_channel;
    FlutterViewController *_flutterController;
    BOOL _isPlaying;
    AVPlayer *_player;
    FlutterResult _result;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel methodChannelWithName:@"com.mcs.plugins/stereo" binaryMessenger:[registrar messenger]];
    StereoPlugin* instance = [[StereoPlugin alloc] initWithChannel:channel];

    [registrar addMethodCallDelegate:instance channel:channel];
    [registrar addApplicationDelegate:instance];
}

- (StereoPlugin *)initWithChannel:(FlutterMethodChannel * _Nonnull)channel {
    self = [super init];

    if (self) {
        _channel = channel;
    }

    return self;
}

#pragma mark - UIApplicationDelegate methods

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Begin audio session.
    [self _beginAudioSession];

    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [self _endAudioSession];
}

#pragma mark - FlutterPlugin methods

- (void)handleMethodCall:(FlutterMethodCall * _Nonnull)call result:(FlutterResult _Nonnull)result {
    if ([@"app.loadItemWithURL" isEqualToString:call.method]) {
        if (call.arguments != nil) {
            if (![call.arguments isKindOfClass:[NSString class]]) {
                result([FlutterError errorWithCode:@"WRONG_FORMAT" message:@"The specified URL must be a string." details:nil]);
            }

            NSURL *url = [NSURL URLWithString:(NSString *)call.arguments];
            [self _loadItemWithURL:url];

            result(@0);
        }
        else {
            result([FlutterError errorWithCode:@"NO_URL" message:@"No URL was specified." details:nil]);
        }
    }
    else if ([@"app.showMediaPicker" isEqualToString:call.method]) {
        if (_result != nil) {
            _result([FlutterError errorWithCode:@"MULTIPLE_REQUESTS" message:@"Cancelled by a second request." details:nil]);

            _result = nil;
        }
        _result = result;

        [self _showMediaPicker];
    }
    else if ([@"app.togglePlaying" isEqualToString:call.method]) {
        result(@([self _togglePlayPause]));
    }
    else {
        result(FlutterMethodNotImplemented);
    }
}

#pragma mark - Private methods

- (void)_beginAudioSession {
    NSError *error;
    AVAudioSession *session = [AVAudioSession sharedInstance];

    [session setCategory:AVAudioSessionCategoryPlayback error:&error];
    // If an error occured, display an alert.
    if (error != nil) {
        [self _showMediaPlayerAlert];
    }

    [session setActive:YES error:&error];
    if (error != nil) {
        [self _showMediaPlayerAlert];
    }

    _player = [[AVPlayer alloc] initWithPlayerItem:nil];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];

    [[[MPRemoteCommandCenter sharedCommandCenter] pauseCommand] addTarget:self action:@selector(_notifyPlayPause:)];
    [[[MPRemoteCommandCenter sharedCommandCenter] playCommand] addTarget:self action:@selector(_notifyPlayPause:)];
    [[[MPRemoteCommandCenter sharedCommandCenter] togglePlayPauseCommand] addTarget:self action:@selector(_notifyPlayPause:)];
}

- (void)_endAudioSession {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setActive:NO error:nil];
    _player = nil;
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
}

- (void)_loadItemWithURL:(NSURL * _Nonnull)url {
    AVAsset *asset = [AVAsset assetWithURL:url];
    NSArray *assetKeys = @[@"playable", @"hasProtectedContent"];

    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset automaticallyLoadedAssetKeys:assetKeys];

    [_player replaceCurrentItemWithPlayerItem:item];
}

- (MPRemoteCommandHandlerStatus)_notifyPlayPause:(MPRemoteCommandEvent *)event {
    [_channel invokeMethod:@"event.togglePlayPause" arguments:nil];
}

- (void)_showMediaPicker {
    MCMediaPickerController *picker = [[MCMediaPickerController alloc] initWithResult:_result];

    // If Flutter controller isn't defined, define it.
    if (_flutterController == nil) {
        _flutterController = (FlutterViewController *)[[UIApplication sharedApplication] keyWindow].rootViewController;
    }

    [_flutterController presentViewController:picker animated:YES completion:nil];
}

- (void)_showMediaPlayerAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"There was an error with the music player. Please restart the app." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];

    [alert addAction:okButton];
    [_flutterController presentViewController:alert animated:YES completion:nil];
}

- (BOOL)_togglePlayPause {
    if (_isPlaying) {
        [_player pause];
    }
    else {
        [_player play];
    }

    _isPlaying = !_isPlaying;

    return _isPlaying;
}

@end
