//
//  HomeCollectionViewCell.m
//  TuSDKEvaDemo
//
//  Created by tutu on 2019/6/26.
//  Copyright © 2019 TuSdk. All rights reserved.
//

#import "HomeCollectionViewCell.h"
#import "DownLoadFileModel.h"
#import "DownLoadManager.h"
#import "TuSDKFramework.h"
#import "UIImageView+WebCache.h"

@interface HomeCollectionViewCell()<DownLoadFileModelDelegate>
//下载进度
@property (nonatomic, assign) float progress;

@end


@implementation HomeCollectionViewCell


- (void)awakeFromNib {
    [super awakeFromNib];
//    self.image.layer.cornerRadius = 5;
//    self.image.layer.masksToBounds = YES;
    
    self.backgroundColor = lsqRGB(34,34,34);
    
    self.progressView.trackTintColor = [UIColor colorWithRed:77 / 255.0 green:88 / 255.0 blue:102 / 255.0 alpha:0.8];
    self.progressView.progress = 0;
    self.progressView.progressTintColor = [UIColor lsqClorWithHex:@"#776AF7"];
    self.progressView.hidden = self.progressLabel.hidden = YES;
    
    
}


- (void)setModel:(DownLoadFileModel *)model {
    _model = model;
    _text.text = model.name;
//    _image.image = [UIImage imageWithContentsOfFile: [[NSBundle mainBundle] pathForResource:model.image ofType:@"jpg"]];
    [_image sd_setImageWithURL:[NSURL URLWithString:model.image] placeholderImage:[UIImage imageNamed:@"placeholder_logo"]];
    
    _actionButton.hidden = model.filePath != nil;
    
    _actionButton.selected = (model.status == DownloadStateResumed || model.status == DownloadStateWait);
    self.progressView.hidden = self.progressLabel.hidden = YES;
    if (_actionButton.selected) {
        [self startRotating];
    } else {
        [self stopRotating];
    }
    model.delegate = self;
}


- (IBAction)click:(UIButton *)sender {
    
    // 查看是否下载
    // 下载完成
    if (_model.status == DownloadStateCompleted) {
        return;
    }
    
    sender.selected = !sender.isSelected;
    if (sender.selected) {
        [[DownLoadManager defaultManager] downLoadWithFile:_model];
    } else {
        [[DownLoadManager defaultManager] pauseDownLoadWithFile:_model];
    }
}

- (void)clickButton {
    [self click:_actionButton];
}

- (void)updateDownladProgress
{
    _actionButton.hidden = YES;
    self.progressView.hidden = self.progressLabel.hidden = !_actionButton.hidden;
}


#pragma mark - DownLoadFileModelDelegate
- (void)downloadFileModel:(DownLoadFileModel *)fileModel progressChanged:(float)progress {
    // 进度改变
    self.progress = progress;
    self.progressView.progress = progress;
    NSLog(@"下载进度: %02f", progress);
}

- (void)downloadFileModel:(DownLoadFileModel *)fileModel cacheLength:(NSInteger)cacheLength fileLength:(NSInteger)fileLength
{
    if (_model.status == DownloadStateResumed) {
        self.actionButton.hidden = YES;
        self.progressLabel.hidden = NO;
        
        NSShadow *shadow = [[NSShadow alloc] init];
        shadow.shadowBlurRadius = 5;
        shadow.shadowOffset = CGSizeMake(0, 0);
        shadow.shadowColor = [UIColor blackColor];
        NSString *progressStr = [NSString stringWithFormat:@"%.2f/%.2fMB", cacheLength / 1024.0 / 1024.0, fileLength / 1024.0 / 1024.0];
        NSAttributedString *attString = [[NSAttributedString alloc] initWithString:progressStr attributes:@{NSShadowAttributeName:shadow}];
        self.progressLabel.attributedText = attString;
    }
}

- (void)downloadFileModel:(DownLoadFileModel *)fileModel statusChanged:(DownloadState)status {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressView.hidden = self.progressLabel.hidden = NO;
        
        // 状态改变
        switch (status) {
            case DownloadStateNone:
                // 下载中
                NSLog(@"status: 未知");
                self.actionButton.selected = NO;
                [self stopRotating];
                break;
            case DownloadStateResumed:
                // 下载中
                NSLog(@"status: 下载中");
                [self resumeRotate];
                break;
                
            case DownloadStateWait:
                // 等待中
                NSLog(@"status: 下载等待中");
                [self resumeRotate];
                break;
                
            case DownloadStateStoped:
                // 停止
                NSLog(@"status: 下载暂停");
                [self stopRotating];
                break;
                
            case DownloadStateCompleted:
                // 完成
                NSLog(@"status: 下载完成");
                self.actionButton.selected = NO;
                self.progressView.hidden = self.progressLabel.hidden = YES;
                [self stopRotating];
                break;
                
            case DownloadStateError:
                // 出错
                NSLog(@"status: 下载出错");
                self.actionButton.selected = NO;
                self.progressView.hidden = self.progressLabel.hidden = YES;
                [self stopRotating];
                break;
                
            case DownloadStateErrorNotFoundResouse:
                NSLog(@"status: 下载的资源不存在");
                //[[TuSDK shared].messageHub showToast:@"下载的资源不存在"];
                self.actionButton.selected = NO;
                self.progressView.hidden = self.progressLabel.hidden = YES;
                break;
            default:
                break;
        }
        self.actionButton.hidden = fileModel.filePath != nil;
    });
    
}


#pragma mark - 按钮旋转动画
- (void)willDisplay {
    if (_model.status == DownloadStateResumed || _model.status == DownloadStateWait) {
        [self resumeRotate];
    }
}

// 开始旋转
- (void) startRotating {
    CABasicAnimation* rotateAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    rotateAnimation.fromValue = [NSNumber numberWithFloat:0.0];
    rotateAnimation.toValue = [NSNumber numberWithFloat:M_PI * 2];   // 旋转一周
    rotateAnimation.duration = 2.0;                                 // 旋转时间20秒
    rotateAnimation.repeatCount = MAXFLOAT;                          // 重复次数，这里用最大次数
    rotateAnimation.removedOnCompletion = NO;
    [self.actionButton.layer addAnimation:rotateAnimation forKey:@"rotateAnimation"];
}

 
// 停止旋转, 这里停止后直接移除了，暂停和动画的显示是两种不一样的状态
- (void) stopRotating {
    [self.actionButton.layer removeAnimationForKey:@"rotateAnimation"];
//    CFTimeInterval pausedTime = [self.actionButton.layer convertTime:CACurrentMediaTime() fromLayer:nil];
//    self.actionButton.layer.speed = 0.0;                                          // 停止旋转
//    self.actionButton.layer.timeOffset = pausedTime;                              // 保存时间，恢复旋转需要用到
}

 
// 恢复旋转
- (void) resumeRotate {
    [self startRotating];
    
//    if (self.actionButton.layer.timeOffset == 0) {
//        [self startRotating];
//        return;
//    }
//
//    CFTimeInterval pausedTime = self.actionButton.layer.timeOffset;
//    self.actionButton.layer.speed = 1.0;                                         // 开始旋转
//    self.actionButton.layer.timeOffset = 0.0;
//    self.actionButton.layer.beginTime = 0.0;
//    CFTimeInterval timeSincePause = [self.actionButton.layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;                                             // 恢复时间
//    self.actionButton.layer.beginTime = timeSincePause;                          // 从暂停的时间点开始旋转
}


@end
