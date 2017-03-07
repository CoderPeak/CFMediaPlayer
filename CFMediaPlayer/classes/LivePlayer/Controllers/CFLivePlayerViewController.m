//
//  CFLivePlayerViewController.m
//  CFMediaPlayer
//
//  Created by Peak on 17/3/7.
//  Copyright © 2017年 Peak. All rights reserved.
//

#import "CFLivePlayerViewController.h"
#import <TXRTMPSDK/TXLivePlayListener.h>

#import <mach/mach.h>

#define TEST_MUTE   0


#define RTMP_URL    @"rtmp://live.hkstv.hk.lxdns.com/live/hks"

typedef NS_ENUM(NSInteger, ENUM_TYPE_CACHE_STRATEGY)
{
    CACHE_STRATEGY_FAST           = 1,  //极速
    CACHE_STRATEGY_SMOOTH         = 2,  //流畅
    CACHE_STRATEGY_AUTO           = 3,  //自动
};

#define CACHE_TIME_FAST             1.0f
#define CACHE_TIME_SMOOTH           5.0f

#define CACHE_TIME_AUTO_MIN         5.0f
#define CACHE_TIME_AUTO_MAX         10.0f

@interface CFLivePlayerViewController ()<UITextFieldDelegate, TXLivePlayListener>

@end

@implementation CFLivePlayerViewController
{
    BOOL        _bHWDec;
    UISlider*   _playProgress;
    UILabel*    _playDuration;
    UILabel*    _playStart;
    UIButton*   _btnPlayMode;
    UIButton*   _btnHWDec;
    long long   _trackingTouchTS;
    BOOL        _startSeek;
    BOOL        _videoPause;
    CGRect _videoWidgetFrame; //改变videoWidget的frame时候记得对其重新进行赋值
    UIImageView * _loadingImageView;
    BOOL        _appIsInterrupt;
    float       _sliderValue;
    TX_Enum_PlayType _playType;
    long long	_startPlayTS;
    UIView *    mVideoContainer;
    NSString    *_playUrl;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"直播播放";
    
    [self initUI];
}

- (void)statusBarOrientationChanged:(NSNotification *)note  {
    //    CGRect frame = self.view.frame;
    //    switch ([[UIDevice currentDevice] orientation]) {
    //        case UIDeviceOrientationPortrait:        //activity竖屏模式，竖屏推流
    //        {
    //            mVideoContainer.frame = CGRectMake(0, 0,frame.size.width,frame.size.width*9/16);
    //        }
    //            break;
    //        case UIDeviceOrientationLandscapeRight:   //activity横屏模式，home在左横屏推流
    //        {
    //            mVideoContainer.frame = CGRectMake(0, 0,frame.size.width,frame.size.height);
    //        }
    //            break;
    //        case UIDeviceOrientationLandscapeLeft:   //activity横屏模式，home在左横屏推流
    //        {
    //            mVideoContainer.frame = CGRectMake(0, 0,frame.size.width,frame.size.height);
    //        }
    //            break;
    //        default:
    //            break;
    //    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

- (void)initUI {
    for (UIView *view in self.view.subviews) {
        [view removeFromSuperview];
    }
    self.wantsFullScreenLayout = YES;
    _videoWidgetFrame = [UIScreen mainScreen].bounds;
    
    UIImage *image = [UIImage imageNamed:@"background@2x.jpg"];
    self.view.layer.contents = (id)image.CGImage;
    
    // remove all subview
    for (UIView *view in [self.view subviews]) {
        [view removeFromSuperview];
    }
    
    CGSize size = [[UIScreen mainScreen] bounds].size;
    
    int icon_size = size.width / 10;
    
    _cover = [[UIView alloc]init];
    _cover.frame  = CGRectMake(10.0f, 55 + 2*icon_size, size.width - 20, size.height - 75 - 3 * icon_size);
    _cover.backgroundColor = [UIColor whiteColor];
    _cover.alpha  = 0.5;
    _cover.hidden = YES;
    [self.view addSubview:_cover];
    
    int logheadH = 65;
    _statusView = [[UITextView alloc] initWithFrame:CGRectMake(10.0f, 55 + 2*icon_size, size.width - 20,  logheadH)];
    _statusView.backgroundColor = [UIColor clearColor];
    _statusView.alpha = 1;
    _statusView.textColor = [UIColor blackColor];
    _statusView.editable = NO;
    _statusView.hidden = YES;
    [self.view addSubview:_statusView];
    
    _logViewEvt = [[UITextView alloc] initWithFrame:CGRectMake(10.0f, 55 + 2*icon_size + logheadH, size.width - 20, size.height - 75 - 3 * icon_size - logheadH)];
    _logViewEvt.backgroundColor = [UIColor clearColor];
    _logViewEvt.alpha = 1;
    _logViewEvt.textColor = [UIColor blackColor];
    _logViewEvt.editable = NO;
    _logViewEvt.hidden = YES;
    [self.view addSubview:_logViewEvt];
    
   
    
    self.txtRtmpUrl = [[UITextField alloc] initWithFrame:CGRectMake(10, 40 + icon_size + 10, size.width- 25 - icon_size, icon_size)];
    [self.txtRtmpUrl setBorderStyle:UITextBorderStyleRoundedRect];
    self.txtRtmpUrl.placeholder = RTMP_URL;
    self.txtRtmpUrl.text = @"";
    self.txtRtmpUrl.background = [UIImage imageNamed:@"Input_box"];
    self.txtRtmpUrl.alpha = 0.5;
    self.txtRtmpUrl.autocapitalizationType = UITextAutocorrectionTypeNo;
    self.txtRtmpUrl.delegate = self;
    [self.view addSubview:self.txtRtmpUrl];
    
    UIButton* btnScan = [UIButton buttonWithType:UIButtonTypeCustom];
    btnScan.frame = CGRectMake(size.width - 10 - icon_size , 40 + icon_size + 10, icon_size, icon_size);
    [btnScan setImage:[UIImage imageNamed:@"QR_code"] forState:UIControlStateNormal];
    [btnScan addTarget:self action:@selector(clickScan:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnScan];
    
    int icon_length = 7;
    int icon_gap = (size.width - icon_size*(icon_length-1))/icon_length;
    int hh = [[UIScreen mainScreen] bounds].size.height - icon_size - 50;
    _playStart = [[UILabel alloc]init];
    _playStart.frame = CGRectMake(20, hh, 50, 30);
    [_playStart setText:@"00:00"];
    [_playStart setTextColor:[UIColor whiteColor]];
    _playStart.hidden = YES;
    [self.view addSubview:_playStart];
    
    _playDuration = [[UILabel alloc]init];
    _playDuration.frame = CGRectMake([[UIScreen mainScreen] bounds].size.width-70, hh, 50, 30);
    [_playDuration setText:@"00:00"];
    [_playDuration setTextColor:[UIColor whiteColor]];
    _playDuration.hidden = YES;
    [self.view addSubview:_playDuration];
    
    _playProgress=[[UISlider alloc]initWithFrame:CGRectMake(70, hh, [[UIScreen mainScreen] bounds].size.width-140, 30)];
    _playProgress.maximumValue = 0;
    _playProgress.minimumValue = 0;
    _playProgress.value = 0;
    _playProgress.continuous = NO;
    [_playProgress addTarget:self action:@selector(onSeek:) forControlEvents:(UIControlEventValueChanged)];
    [_playProgress addTarget:self action:@selector(onSeekBegin:) forControlEvents:(UIControlEventTouchDown)];
    [_playProgress addTarget:self action:@selector(onDrag:) forControlEvents:UIControlEventTouchDragInside];
    _playProgress.hidden = YES;
    [self.view addSubview:_playProgress];
    
    int btn_index = 0;
    _play_switch = NO;
    _btnPlay = [self createBottomBtnIndex:btn_index++ Icon:@"start" Action:@selector(clickPlay:) Gap:icon_gap Size:icon_size];
    
    if (self.isLivePlay) {
        _btnClose = nil;
    } else {
        _btnClose = [self createBottomBtnIndex:btn_index++ Icon:@"close" Action:@selector(clickClose:) Gap:icon_gap Size:icon_size];
    }
    
    _log_switch = NO;
    [self createBottomBtnIndex:btn_index++ Icon:@"log" Action:@selector(clickLog:) Gap:icon_gap Size:icon_size];
    
    _bHWDec = NO;
    _btnHWDec = [self createBottomBtnIndex:btn_index++ Icon:@"quick2" Action:@selector(onClickHardware:) Gap:icon_gap Size:icon_size];
    
    _screenPortrait = NO;
    [self createBottomBtnIndex:btn_index++ Icon:@"portrait" Action:@selector(clickScreenOrientation:) Gap:icon_gap Size:icon_size];
    
    _renderFillScreen = YES;
    [self createBottomBtnIndex:btn_index++ Icon:@"adjust" Action:@selector(clickRenderMode:) Gap:icon_gap Size:icon_size];
    
    _txLivePlayer = [[TXLivePlayer alloc] init];
    
    if (!self.isLivePlay) {
        _btnCacheStrategy = nil;
    } else {
        _btnCacheStrategy = [self createBottomBtnIndex:btn_index++ Icon:@"cache_time" Action:@selector(onAdjustCacheStrategy:) Gap:icon_gap Size:icon_size];
    }
    [self setCacheStrategy:CACHE_STRATEGY_AUTO];
    
    
    _videoPause = NO;
    _trackingTouchTS = 0;
    
    if (!self.isLivePlay) {
        _playStart.hidden = NO;
        _playDuration.hidden = NO;
        _playProgress.hidden = NO;
    } else {
        _playStart.hidden = YES;
        _playDuration.hidden = YES;
        _playProgress.hidden = YES;
    }
    
    //loading imageview
    float width = 34;
    float height = 34;
    float offsetX = (self.view.frame.size.width - width) / 2;
    float offsetY = (self.view.frame.size.height - height) / 2;
    NSMutableArray *array = [[NSMutableArray alloc] initWithObjects:[UIImage imageNamed:@"loading_image0.png"],[UIImage imageNamed:@"loading_image1.png"],[UIImage imageNamed:@"loading_image2.png"],[UIImage imageNamed:@"loading_image3.png"],[UIImage imageNamed:@"loading_image4.png"],[UIImage imageNamed:@"loading_image5.png"],[UIImage imageNamed:@"loading_image6.png"],[UIImage imageNamed:@"loading_image7.png"], nil];
    _loadingImageView = [[UIImageView alloc] initWithFrame:CGRectMake(offsetX, offsetY, width, height)];
    _loadingImageView.animationImages = array;
    _loadingImageView.animationDuration = 1;
    _loadingImageView.hidden = YES;
    [self.view addSubview:_loadingImageView];
    
    _vCacheStrategy = [[UIView alloc]init];
    _vCacheStrategy.frame = CGRectMake(0, size.height-120, size.width, 120);
    [_vCacheStrategy setBackgroundColor:[UIColor whiteColor]];
    
    UILabel* title= [[UILabel alloc]init];
    title.frame = CGRectMake(0, 0, size.width, 50);
    [title setText:@"缓存策略"];
    title.textAlignment = NSTextAlignmentCenter;
    [title setFont:[UIFont fontWithName:@"" size:14]];
    
    [_vCacheStrategy addSubview:title];
    
    int gap = 30;
    int width2 = (size.width - gap*2 - 20) / 3;
    _radioBtnFast = [UIButton buttonWithType:UIButtonTypeCustom];
    _radioBtnFast.frame = CGRectMake(10, 60, width2, 40);
    [_radioBtnFast setTitle:@"极速" forState:UIControlStateNormal];
    [_radioBtnFast addTarget:self action:@selector(onAdjustFast:) forControlEvents:UIControlEventTouchUpInside];
    
    _radioBtnSmooth = [UIButton buttonWithType:UIButtonTypeCustom];
    _radioBtnSmooth.frame = CGRectMake(10 + gap + width2, 60, width2, 40);
    [_radioBtnSmooth setTitle:@"流畅" forState:UIControlStateNormal];
    [_radioBtnSmooth addTarget:self action:@selector(onAdjustSmooth:) forControlEvents:UIControlEventTouchUpInside];
    
    _radioBtnAUTO = [UIButton buttonWithType:UIButtonTypeCustom];
    _radioBtnAUTO.frame = CGRectMake(size.width - 10 - width2, 60, width2, 40);
    [_radioBtnAUTO setTitle:@"自动" forState:UIControlStateNormal];
    [_radioBtnAUTO addTarget:self action:@selector(onAdjustAuto:) forControlEvents:UIControlEventTouchUpInside];
    
    [_vCacheStrategy addSubview:_radioBtnFast];
    [_vCacheStrategy addSubview:_radioBtnSmooth];
    [_vCacheStrategy addSubview:_radioBtnAUTO];
    _vCacheStrategy.hidden = YES;
    [self.view addSubview:_vCacheStrategy];
    
    CGRect VideoFrame = self.view.bounds;
    mVideoContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VideoFrame.size.width, VideoFrame.size.height)];
    [self.view insertSubview:mVideoContainer atIndex:0];
    mVideoContainer.center = self.view.center;
}

- (UIButton*)createBottomBtnIndex:(int)index Icon:(NSString*)icon Action:(SEL)action Gap:(int)gap Size:(int)size
{
    UIButton* btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake((index+1)*gap + index*size, [[UIScreen mainScreen] bounds].size.height - size - 10, size, size);
    [btn setImage:[UIImage imageNamed:icon] forState:UIControlStateNormal];
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    return btn;
}

//在低系统（如7.1.2）可能收不到这个回调，请在onAppDidEnterBackGround和onAppWillEnterForeground里面处理打断逻辑
- (void) onAudioSessionEvent: (NSNotification *) notification
{
    NSDictionary *info = notification.userInfo;
    AVAudioSessionInterruptionType type = [info[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    if (type == AVAudioSessionInterruptionTypeBegan) {
        if (_play_switch == YES && _appIsInterrupt == NO) {
            if (_playType == PLAY_TYPE_VOD_FLV || _playType == PLAY_TYPE_VOD_HLS || _playType == PLAY_TYPE_VOD_MP4) {
                if (!_videoPause) {
                    [_txLivePlayer pause];
                }
            }
            _appIsInterrupt = YES;
        }
    }else{
        AVAudioSessionInterruptionOptions options = [info[AVAudioSessionInterruptionOptionKey] unsignedIntegerValue];
        if (options == AVAudioSessionInterruptionOptionShouldResume) {
            if (_play_switch == YES && _appIsInterrupt == YES) {
                if (_playType == PLAY_TYPE_VOD_FLV || _playType == PLAY_TYPE_VOD_HLS || _playType == PLAY_TYPE_VOD_MP4) {
                    if (!_videoPause) {
                        [_txLivePlayer resume];
                    }
                }
                _appIsInterrupt = NO;
            }
        }
    }
}

- (void)onAppDidEnterBackGround:(UIApplication*)app {
    if (_play_switch == YES) {
        if (_playType == PLAY_TYPE_VOD_FLV || _playType == PLAY_TYPE_VOD_HLS || _playType == PLAY_TYPE_VOD_MP4) {
            if (!_videoPause) {
                [_txLivePlayer pause];
            }
        }
    }
}

- (void)onAppWillEnterForeground:(UIApplication*)app {
    if (_play_switch == YES) {
        if (_playType == PLAY_TYPE_VOD_FLV || _playType == PLAY_TYPE_VOD_HLS || _playType == PLAY_TYPE_VOD_MP4) {
            if (!_videoPause) {
                [_txLivePlayer resume];
            }
        }
    }
}

- (void)onAppDidBecomeActive:(UIApplication*)app {
    if (_play_switch == YES && _appIsInterrupt == YES) {
        if (_playType == PLAY_TYPE_VOD_FLV || _playType == PLAY_TYPE_VOD_HLS || _playType == PLAY_TYPE_VOD_MP4) {
            if (!_videoPause) {
                [_txLivePlayer resume];
            }
        }
        _appIsInterrupt = NO;
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if (_play_switch == YES) {
        [self stopRtmp];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAudioSessionEvent:) name:AVAudioSessionInterruptionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppDidEnterBackGround:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarOrientationChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

#pragma -- example code bellow
- (void)clearLog {
    _tipsMsg = @"";
    _logMsg = @"";
    [_statusView setText:@""];
    [_logViewEvt setText:@""];
    _startTime = [[NSDate date]timeIntervalSince1970]*1000;
    _lastTime = _startTime;
}

-(BOOL)checkPlayUrl:(NSString*)playUrl {
    if (!([playUrl hasPrefix:@"http:"] || [playUrl hasPrefix:@"https:"] || [playUrl hasPrefix:@"rtmp:"] )) {
        [self toastTip:@"播放地址不合法，目前仅支持rtmp,flv,hls,mp4播放方式!"];
        return NO;
    }
    if (self.isLivePlay) {
        if ([playUrl hasPrefix:@"rtmp:"]) {
            _playType = PLAY_TYPE_LIVE_RTMP;
        } else if (([playUrl hasPrefix:@"https:"] || [playUrl hasPrefix:@"http:"]) && [playUrl rangeOfString:@".flv"].length > 0) {
            _playType = PLAY_TYPE_LIVE_FLV;
        } else{
            [self toastTip:@"播放地址不合法，直播目前仅支持rtmp,flv播放方式!"];
            return NO;
        }
    } else {
        if ([playUrl hasPrefix:@"https:"] || [playUrl hasPrefix:@"http:"]) {
            if ([playUrl rangeOfString:@".flv"].length > 0) {
                _playType = PLAY_TYPE_VOD_FLV;
            } else if ([playUrl rangeOfString:@".m3u8"].length > 0){
                _playType= PLAY_TYPE_VOD_HLS;
            } else if ([playUrl rangeOfString:@".mp4"].length > 0){
                _playType= PLAY_TYPE_VOD_MP4;
            } else {
                [self toastTip:@"播放地址不合法，点播目前仅支持flv,hls,mp4播放方式!"];
                return NO;
            }
            
        } else {
            [self toastTip:@"播放地址不合法，点播目前仅支持flv,hls,mp4播放方式!"];
            return NO;
        }
    }
    
    return YES;
}
-(BOOL)startRtmp{
    NSString* playUrl = self.txtRtmpUrl.text;
    if (playUrl.length == 0) {
        playUrl = RTMP_URL;
    }
    
    if (![self checkPlayUrl:playUrl]) {
        return NO;
    }
    
    [self clearLog];
    
    NSArray* ver = [TXLivePlayer getSDKVersion];
    if ([ver count] >= 3) {
        // arvinwu add. 增加播放按钮事件的时间打印。
        unsigned long long recordTime = [[NSDate date] timeIntervalSince1970]*1000;
        int mil = recordTime%1000;
        NSDateFormatter* format = [[NSDateFormatter alloc] init];
        format.dateFormat = @"hh:mm:ss";
        NSString* time = [format stringFromDate:[NSDate date]];
        NSString* log = [NSString stringWithFormat:@"[%@.%-3.3d] 点击播放按钮", time, mil];
        _logMsg = [NSString stringWithFormat:@"rtmp sdk version: %@.%@.%@\n%@",ver[0],ver[1],ver[2],log];
        [_logViewEvt setText:_logMsg];
    }
    
    if(_txLivePlayer != nil)
    {
        _txLivePlayer.delegate = self;
        [_txLivePlayer setupVideoWidget:CGRectMake(0, 0, 0, 0) containView:mVideoContainer insertIndex:0];
        //设置播放器缓存策略
        //这里将播放器的策略设置为自动调整，调整的范围设定为1到4s，您也可以通过setCacheTime将播放器策略设置为采用
        //固定缓存时间。如果您什么都不调用，播放器将采用默认的策略（默认策略为自动调整，调整范围为1到4s）
        //[_txLivePlayer setCacheTime:5];
        //[_txLivePlayer setMinCacheTime:1];
        //[_txLivePlayer setMaxCacheTime:4];
        int result = [_txLivePlayer startPlay:playUrl type:_playType];
        if (result == -1)
        {
            [self toastTip:@"非腾讯云链接，若要放开限制请联系腾讯云商务团队"];
            return NO;
        }
        if( result != 0)
        {
            NSLog(@"播放器启动失败");
            return NO;
        }
        
        if (_screenPortrait) {
            [_txLivePlayer setRenderRotation:HOME_ORIENTATION_RIGHT];
        } else {
            [_txLivePlayer setRenderRotation:HOME_ORIENTATION_DOWN];
        }
        if (_renderFillScreen) {
            [_txLivePlayer setRenderMode:RENDER_MODE_FILL_SCREEN];
        } else {
            [_txLivePlayer setRenderMode:RENDER_MODE_FILL_EDGE];
        }
        
        [self startLoadingAnimation];
        
        _videoPause = NO;
        [_btnPlay setImage:[UIImage imageNamed:@"suspend"] forState:UIControlStateNormal];
    }
    [self startLoadingAnimation];
    _startPlayTS = [[NSDate date]timeIntervalSince1970]*1000;
    
    _playUrl = playUrl;
    
    return YES;
}


- (void)stopRtmp{
    _playUrl = @"";
    [self stopLoadingAnimation];
    if(_txLivePlayer != nil)
    {
        _txLivePlayer.delegate = nil;
        [_txLivePlayer stopPlay];
        [_txLivePlayer removeVideoWidget];
    }
}

#pragma - ui event response.
- (void) clickPlay:(UIButton*) sender {
    //-[UIApplication setIdleTimerDisabled:]用于控制自动锁屏，SDK内部并无修改系统锁屏的逻辑
    if (_play_switch == YES)
    {
        if (_playType == PLAY_TYPE_VOD_FLV || _playType == PLAY_TYPE_VOD_HLS || _playType == PLAY_TYPE_VOD_MP4) {
            if (_videoPause) {
                [_txLivePlayer resume];
                [sender setImage:[UIImage imageNamed:@"suspend"] forState:UIControlStateNormal];
                [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
            } else {
                [_txLivePlayer pause];
                [sender setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
                [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
            }
            _videoPause = !_videoPause;
            
            
        } else {
            _play_switch = NO;
            [self stopRtmp];
            [sender setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
            [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
        }
        
    }
    else
    {
        if (![self startRtmp]) {
            return;
        }
        
        [sender setImage:[UIImage imageNamed:@"suspend"] forState:UIControlStateNormal];
        _play_switch = YES;
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    }
}

- (void)clickClose:(UIButton*)sender {
    if (_play_switch) {
        _play_switch = NO;
        [self stopRtmp];
        [_btnPlay setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
        _playStart.text = @"00:00";
        [_playDuration setText:@"00:00"];
        [_playProgress setValue:0];
        [_playProgress setMaximumValue:0];
    }
}

- (void) clickLog:(UIButton*) sender {
    if (_log_switch == YES)
    {
        _statusView.hidden = YES;
        _logViewEvt.hidden = YES;
        [sender setImage:[UIImage imageNamed:@"log"] forState:UIControlStateNormal];
        _cover.hidden = YES;
        _log_switch = NO;
    }
    else
    {
        _statusView.hidden = NO;
        _logViewEvt.hidden = NO;
        [sender setImage:[UIImage imageNamed:@"log2"] forState:UIControlStateNormal];
        _cover.hidden = NO;
        _log_switch = YES;
    }
}

- (void) clickScreenOrientation:(UIButton*) sender {
    _screenPortrait = !_screenPortrait;
    
    if (_screenPortrait) {
        [sender setImage:[UIImage imageNamed:@"landscape"] forState:UIControlStateNormal];
        [_txLivePlayer setRenderRotation:HOME_ORIENTATION_RIGHT];
    } else {
        [sender setImage:[UIImage imageNamed:@"portrait"] forState:UIControlStateNormal];
        [_txLivePlayer setRenderRotation:HOME_ORIENTATION_DOWN];
    }
}

- (void) clickRenderMode:(UIButton*) sender {
    _renderFillScreen = !_renderFillScreen;
    
    if (_renderFillScreen) {
        [sender setImage:[UIImage imageNamed:@"adjust"] forState:UIControlStateNormal];
        [_txLivePlayer setRenderMode:RENDER_MODE_FILL_SCREEN];
    } else {
        [sender setImage:[UIImage imageNamed:@"fill"] forState:UIControlStateNormal];
        [_txLivePlayer setRenderMode:RENDER_MODE_FILL_EDGE];
    }
}

- (void) setCacheStrategy:(NSInteger) nCacheStrategy
{
    if (_btnCacheStrategy == nil || _cacheStrategy == nCacheStrategy)    return;
    
    if (_config == nil)
    {
        _config = [[TXLivePlayConfig alloc] init];
    }
    
    _cacheStrategy = nCacheStrategy;
    switch (_cacheStrategy) {
        case CACHE_STRATEGY_FAST:
            _config.bAutoAdjustCacheTime = YES;
            _config.minAutoAdjustCacheTime = CACHE_TIME_FAST;
            _config.maxAutoAdjustCacheTime = CACHE_TIME_FAST;
            [_txLivePlayer setConfig:_config];
            break;
            
        case CACHE_STRATEGY_SMOOTH:
            _config.bAutoAdjustCacheTime = NO;
            _config.cacheTime = CACHE_TIME_SMOOTH;
            [_txLivePlayer setConfig:_config];
            break;
            
        case CACHE_STRATEGY_AUTO:
            _config.bAutoAdjustCacheTime = YES;
            _config.minAutoAdjustCacheTime = CACHE_TIME_FAST;
            _config.maxAutoAdjustCacheTime = CACHE_TIME_SMOOTH;
            [_txLivePlayer setConfig:_config];
            break;
            
        default:
            break;
    }
}

- (void) onAdjustCacheStrategy:(UIButton*) sender
{
#if TEST_MUTE
    static BOOL flag = YES;
    [_txLivePlayer setMute:flag];
    flag = !flag;
#else
    _vCacheStrategy.hidden = NO;
    switch (_cacheStrategy) {
        case CACHE_STRATEGY_FAST:
            [_radioBtnFast setBackgroundImage:[UIImage imageNamed:@"black"] forState:UIControlStateNormal];
            [_radioBtnFast setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [_radioBtnSmooth setBackgroundImage:[UIImage imageNamed:@"white"] forState:UIControlStateNormal];
            [_radioBtnSmooth setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [_radioBtnAUTO setBackgroundImage:[UIImage imageNamed:@"white"] forState:UIControlStateNormal];
            [_radioBtnAUTO setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            break;
            
        case CACHE_STRATEGY_SMOOTH:
            [_radioBtnFast setBackgroundImage:[UIImage imageNamed:@"white"] forState:UIControlStateNormal];
            [_radioBtnFast setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [_radioBtnSmooth setBackgroundImage:[UIImage imageNamed:@"black"] forState:UIControlStateNormal];
            [_radioBtnSmooth setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [_radioBtnAUTO setBackgroundImage:[UIImage imageNamed:@"white"] forState:UIControlStateNormal];
            [_radioBtnAUTO setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            break;
            
        case CACHE_STRATEGY_AUTO:
            [_radioBtnFast setBackgroundImage:[UIImage imageNamed:@"white"] forState:UIControlStateNormal];
            [_radioBtnFast setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [_radioBtnSmooth setBackgroundImage:[UIImage imageNamed:@"white"] forState:UIControlStateNormal];
            [_radioBtnSmooth setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [_radioBtnAUTO setBackgroundImage:[UIImage imageNamed:@"black"] forState:UIControlStateNormal];
            [_radioBtnAUTO setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            break;
            
        default:
            break;
    }
#endif
}

- (void) onAdjustFast:(UIButton*) sender
{
    _vCacheStrategy.hidden = YES;
    [self setCacheStrategy:CACHE_STRATEGY_FAST];
}

- (void) onAdjustSmooth:(UIButton*) sender
{
    _vCacheStrategy.hidden = YES;
    [self setCacheStrategy:CACHE_STRATEGY_SMOOTH];
}

- (void) onAdjustAuto:(UIButton*) sender
{
    _vCacheStrategy.hidden = YES;
    [self setCacheStrategy:CACHE_STRATEGY_AUTO];
}

- (void) onClickHardware:(UIButton*) sender {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
        [self toastTip:@"iOS 版本低于8.0，不支持硬件加速."];
        return;
    }
    
    if (_play_switch == YES)
    {
        [self stopRtmp];
    }
    
    _txLivePlayer.enableHWAcceleration = !_bHWDec;
    
    _bHWDec = _txLivePlayer.enableHWAcceleration;
    
    if(_bHWDec)
    {
        [sender setImage:[UIImage imageNamed:@"quick"] forState:UIControlStateNormal];
    }
    else
    {
        [sender setImage:[UIImage imageNamed:@"quick2"] forState:UIControlStateNormal];
    }
    
    if (_play_switch == YES) {
        if (_bHWDec) {
            
            [self toastTip:@"切换为硬解码. 重启播放流程"];
        }
        else
        {
            [self toastTip:@"切换为软解码. 重启播放流程"];
            
        }
        
        [self startRtmp];
    }
    
}

- (void) segmentAction:(UISegmentedControl*) sc
{
    NSInteger idx = sc.selectedSegmentIndex;
    if (0 == idx) {
        [self stopRtmp];
        _play_switch = NO;
        [_btnPlay setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
        
        [self.navigationController popToRootViewControllerAnimated:NO];
    }
    else if (1 == idx) {
        [self stopRtmp];
        _play_switch = NO;
        [_btnPlay setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
        
        self.isLivePlay = NO;
        [self initUI];
        
        self.txtRtmpUrl.text = @"http://220.181.23.202/s1/UvFuJjXR07s7t1nO/38694/v477/3/6/timdOsC5R7yf9FTPdtRqkw.mp4";
        
    }
    else if (2 == idx) {
        [self stopRtmp];
        _play_switch = NO;
        [_btnPlay setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
        
        self.isLivePlay = YES;
        [self initUI];
        
        self.txtRtmpUrl.text = @"rtmp://live.hkstv.hk.lxdns.com/live/hks";
    }
    else if (3 == idx) {
        [self stopRtmp];
        _play_switch = NO;
        [_btnPlay setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
        
        [self.navigationController popToRootViewControllerAnimated:NO];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"HandleNavigation" object:[NSNumber numberWithInteger:idx]];
    }
}

-(void) clickScan:(UIButton*) btn
{
    [self stopRtmp];
    _play_switch = NO;
    [_btnPlay setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
    
}

#pragma -- UISlider - play seek
-(void)onSeek:(UISlider *)slider{
    //    [_txLivePlayer seek:slider.value];
    [_txLivePlayer seek:_sliderValue];
    _trackingTouchTS = [[NSDate date]timeIntervalSince1970]*1000;
    _startSeek = NO;
    NSLog(@"vod seek drag end");
}

-(void)onSeekBegin:(UISlider *)slider{
    _startSeek = YES;
    NSLog(@"vod seek drag begin");
}

-(void)onDrag:(UISlider *)slider {
    float progress = slider.value;
    int intProgress = progress + 0.5;
    _playStart.text = [NSString stringWithFormat:@"%02d:%02d",(int)(intProgress / 60), (int)(intProgress % 60)];
    _sliderValue = slider.value;
}

#pragma -- UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void) touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.txtRtmpUrl resignFirstResponder];
    _vCacheStrategy.hidden = YES;
}


/**
 @method 获取指定宽度width的字符串在UITextView上的高度
 @param textView 待计算的UITextView
 @param Width 限制字符串显示区域的宽度
 @result float 返回的高度
 */
- (float) heightForString:(UITextView *)textView andWidth:(float)width{
    CGSize sizeToFit = [textView sizeThatFits:CGSizeMake(width, MAXFLOAT)];
    return sizeToFit.height;
}

- (void) toastTip:(NSString*)toastInfo
{
    CGRect frameRC = [[UIScreen mainScreen] bounds];
    frameRC.origin.y = frameRC.size.height - 110;
    frameRC.size.height -= 110;
    __block UITextView * toastView = [[UITextView alloc] init];
    
    toastView.editable = NO;
    toastView.selectable = NO;
    
    frameRC.size.height = [self heightForString:toastView andWidth:frameRC.size.width];
    
    toastView.frame = frameRC;
    
    toastView.text = toastInfo;
    toastView.backgroundColor = [UIColor whiteColor];
    toastView.alpha = 0.5;
    
    [self.view addSubview:toastView];
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^(){
        [toastView removeFromSuperview];
        toastView = nil;
    });
}

#pragma ###TXLivePlayListener
-(void) appendLog:(NSString*) evt time:(NSDate*) date mills:(int)mil
{
    if (evt == nil) {
        return;
    }
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    format.dateFormat = @"hh:mm:ss";
    NSString* time = [format stringFromDate:date];
    NSString* log = [NSString stringWithFormat:@"[%@.%-3.3d] %@", time, mil, evt];
    if (_logMsg == nil) {
        _logMsg = @"";
    }
    _logMsg = [NSString stringWithFormat:@"%@\n%@", _logMsg, log ];
    [_logViewEvt setText:_logMsg];
}

-(void) onPlayEvent:(int)EvtID withParam:(NSDictionary*)param;
{
    NSDictionary* dict = param;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (EvtID == PLAY_EVT_PLAY_BEGIN) {
            [self stopLoadingAnimation];
            long long playDelay = [[NSDate date]timeIntervalSince1970]*1000 - _startPlayTS;
            
        } else if (EvtID == PLAY_EVT_PLAY_PROGRESS && !_startSeek) {
            // 避免滑动进度条松开的瞬间可能出现滑动条瞬间跳到上一个位置
            long long curTs = [[NSDate date]timeIntervalSince1970]*1000;
            if (llabs(curTs - _trackingTouchTS) < 500) {
                return;
            }
            _trackingTouchTS = curTs;
            
            float progress = [dict[EVT_PLAY_PROGRESS] floatValue];
            int intProgress = progress + 0.5;
            _playStart.text = [NSString stringWithFormat:@"%02d:%02d", (int)(intProgress / 60), (int)(intProgress % 60)];
            [_playProgress setValue:progress];
            
            float duration = [dict[EVT_PLAY_DURATION] floatValue];
            int intDuration = duration + 0.5;
            if (duration > 0 && _playProgress.maximumValue != duration) {
                [_playProgress setMaximumValue:duration];
                _playDuration.text = [NSString stringWithFormat:@"%02d:%02d", (int)(intDuration / 60), (int)(intDuration % 60)];
            }
            return ;
        } else if (EvtID == PLAY_ERR_NET_DISCONNECT || EvtID == PLAY_EVT_PLAY_END) {
            [self stopRtmp];
            _play_switch = NO;
            [_btnPlay setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
            [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
            [_playProgress setValue:0];
            _playStart.text = @"00:00";
            _videoPause = NO;
        } else if (EvtID == PLAY_EVT_PLAY_LOADING){
            [self startLoadingAnimation];
        }
        
        //        NSLog(@"evt:%d,%@", EvtID, dict);
        long long time = [(NSNumber*)[dict valueForKey:EVT_TIME] longLongValue];
        int mil = time % 1000;
        NSDate* date = [NSDate dateWithTimeIntervalSince1970:time/1000];
        NSString* Msg = (NSString*)[dict valueForKey:EVT_MSG];
        [self appendLog:Msg time:date mills:mil];
    });
}

-(void) onNetStatus:(NSDictionary*) param
{
    NSDictionary* dict = param;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        int netspeed  = [(NSNumber*)[dict valueForKey:NET_STATUS_NET_SPEED] intValue];
        int vbitrate  = [(NSNumber*)[dict valueForKey:NET_STATUS_VIDEO_BITRATE] intValue];
        int abitrate  = [(NSNumber*)[dict valueForKey:NET_STATUS_AUDIO_BITRATE] intValue];
        int cachesize = [(NSNumber*)[dict valueForKey:NET_STATUS_CACHE_SIZE] intValue];
        int dropsize  = [(NSNumber*)[dict valueForKey:NET_STATUS_DROP_SIZE] intValue];
        int jitter    = [(NSNumber*)[dict valueForKey:NET_STATUS_NET_JITTER] intValue];
        int fps       = [(NSNumber*)[dict valueForKey:NET_STATUS_VIDEO_FPS] intValue];
        int width     = [(NSNumber*)[dict valueForKey:NET_STATUS_VIDEO_WIDTH] intValue];
        int height    = [(NSNumber*)[dict valueForKey:NET_STATUS_VIDEO_HEIGHT] intValue];
        float cpu_usage = [(NSNumber*)[dict valueForKey:NET_STATUS_CPU_USAGE] floatValue];
        float cpu_app_usage = [(NSNumber*)[dict valueForKey:NET_STATUS_CPU_USAGE_D] floatValue];
        NSString *serverIP = [dict valueForKey:NET_STATUS_SERVER_IP];
        int codecCacheSize = [(NSNumber*)[dict valueForKey:NET_STATUS_CODEC_CACHE] intValue];
        int nCodecDropCnt = [(NSNumber*)[dict valueForKey:NET_STATUS_CODEC_DROP_CNT] intValue];
        
        NSString* log = [NSString stringWithFormat:@"CPU:%.1f%%|%.1f%%\tRES:%d*%d\tSPD:%dkb/s\nJITT:%d\tFPS:%d\tARA:%dkb/s\nQUE:%d|%d\tDRP:%d|%d\tVRA:%dkb/s\nSVR:%@\t",
                         cpu_app_usage*100,
                         cpu_usage*100,
                         width,
                         height,
                         netspeed,
                         jitter,
                         fps,
                         abitrate,
                         codecCacheSize,
                         cachesize,
                         nCodecDropCnt,
                         dropsize,
                         vbitrate,
                         serverIP];
        [_statusView setText:log];
        
    });
}

-(void) startLoadingAnimation
{
    if (_loadingImageView != nil) {
        _loadingImageView.hidden = NO;
        [_loadingImageView startAnimating];
    }
}

-(void) stopLoadingAnimation
{
    if (_loadingImageView != nil) {
        _loadingImageView.hidden = YES;
        [_loadingImageView stopAnimating];
    }
}

@end
