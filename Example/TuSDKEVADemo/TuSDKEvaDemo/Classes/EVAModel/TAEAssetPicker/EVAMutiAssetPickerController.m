//
//  EVAMutiAssetPickerController.m
//  TuSDKEvaDemo
//
//  Created by 刘鹏程 on 2022/6/8.
//  Copyright © 2022 TuSdk. All rights reserved.
//

#import "EVAMutiAssetPickerController.h"
#import "TTMutiAssetPickSelectView.h"
#import "ImageEditViewController.h"
#import "VideoEditViewController.h"
#import "EditViewController.h"

#import "TTMultiAssetPicker.h"
#import "TTDirectorMediator.h"
#import "TuPopupProgress.h"
#import "TuSDKFrameWork.h"
#import "TuPanelBar.h"


// 标签按钮高度
static const CGFloat kPageButtonHeight = 30;
/** 视频支持的最大边界 */
static const NSUInteger lsqMaxOutputVideoSizeSide = 1080;

@interface EVAMutiAssetPickerController ()<TTMutiAssetPickSelectViewDelegate, TuPanelTabbarDelegate, TTMultiAssetPickerDelegate>

/// 资源选择视图
@property (nonatomic, strong) TTMutiAssetPickSelectView *pickerSelectView;
/// 标签栏
@property (nonatomic, strong) TuPanelBar *pageBar;
/// 全部
@property (nonatomic, strong) TTMultiAssetPicker *allPicker;
/// 最大数量
@property (nonatomic, assign) NSInteger maxSelectCount;
/// 选中的组件
@property (nonatomic, strong) TAEModelVideoItem *selectItem;
/// 是否为当前控制器
@property (nonatomic, assign) BOOL isCurrent;

@end

@implementation EVAMutiAssetPickerController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
    NSMutableArray *childs = [NSMutableArray array];
    [self.navigationController.childViewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![obj isKindOfClass:NSClassFromString(@"EVAPreviewViewController")]) {
            [childs addObject:obj];
        }
    }];
    [self.navigationController setViewControllers:childs];
    self.isCurrent = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    }
    self.isCurrent = NO;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    // Do any additional setup after loading the view.
}

- (void)setupUI
{
    self.view.backgroundColor = UIColor.blackColor;
    self.isCurrent = YES;
    [self setupShowContainer];
    [self setupPageBar];
    [self setPickerView];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:nil];
    self.navigationItem.title = @"";
}

/// 创建标签栏
- (void)setupPageBar
{
    self.pageBar = [[TuPanelBar alloc] init];
    self.pageBar.trackerSize = CGSizeMake(48, 2);
    self.pageBar.itemSelectedColor = lsqRGB(255.0, 204.0, 0);
    self.pageBar.itemNormalColor = [UIColor whiteColor];
    self.pageBar.itemWidth = lsqScreenWidth / 3;
    self.pageBar.itemTitles = @[@"全部", @"视频", @"图片"];
    self.pageBar.itemTitleFont = [UIFont systemFontOfSize:14];
    self.pageBar.delegate = self;
    [self.view addSubview:self.pageBar];
    [self.pageBar mas_makeConstraints:^(MASConstraintMaker *make) {

        make.left.right.top.offset(0);
        make.height.mas_equalTo(kPageButtonHeight);
    }];
}

///底部资源选择视图
- (void)setupShowContainer
{
    self.pickerSelectView = [[TTMutiAssetPickSelectView alloc] init];
    self.pickerSelectView.delegate = self;
    [self.view addSubview:self.pickerSelectView];
    [self.pickerSelectView mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.left.right.bottom.offset(0);
    }];
    
    if (!self.evaMediator) {
        self.evaMediator = [[TAEModelMediator alloc] initWithEvaPath:self.filePath];
    }
    self.pickerSelectView.isCurrent = self.isCurrent;
    self.pickerSelectView.mediator = self.evaMediator;
    // 最大资源选择数量
    self.maxSelectCount = [self.evaMediator imageVideoCount];
}

- (void)setPickerView
{
    [self.view addSubview:self.allPicker.view];
    [self addChildViewController:self.allPicker];

    [self.allPicker.view mas_makeConstraints:^(MASConstraintMaker *make) {

        make.left.right.offset(0);
        make.top.offset(kPageButtonHeight + 5);
        make.bottom.mas_equalTo(self.pickerSelectView.mas_top);
    }];
}


#pragma mark - TTMutiAssetPickSelectViewDelegate
- (void)mutiAssetPickerSelectView:(TTMutiAssetPickSelectView *)view selectAction:(TTMutiAssetPickSelectType)selectType
{
    switch (selectType) {
        case TTMutiAssetPickSelectNext:
        {
            //判断当前选择数量和模版内坑位数量
            NSInteger needReplaceCount = [self.evaMediator replaceVideoCount];
            if (needReplaceCount > 0) {
                [TuPopupProgress showErrorWithStatus:[NSString stringWithFormat:@"还需要选择%ld个素材", (long)needReplaceCount]];
                return;
            }
            
            EditViewController *edit = [[EditViewController alloc] initWithNibName:nil bundle:nil];
            edit.mediator = self.evaMediator;
            edit.editCompleted = ^(TAEModelMediator * _Nonnull mediator) {
                self.pickerSelectView.isCurrent = self.isCurrent;
                self.pickerSelectView.mediator = mediator;
            };
            [self showViewController:edit sender:nil];
        }
            break;
        default:
            break;
    }
}
/**
 * 选中的素材资源
 * @param selectItem  选中组件
 */
- (void)mutiAssetPickerSelectView:(TTMutiAssetPickSelectView *)view selectItem:(TAEModelVideoItem *)selectItem;
{
    _selectItem = selectItem;
    
    //Demo里为无素材坑位模板，只有替换了素材后才能对素材进行编辑操作
    if (_selectItem.isReplace && self.isCurrent) {
        if (_selectItem.isSelectVideo) {
            //视频素材
            VideoEditViewController *edit = [[VideoEditViewController alloc] initWithNibName:nil bundle:nil];

            edit.filePath = self.selectItem.replaceResPath;

            edit.durationTime = self.selectItem.endTime - self.selectItem.startTime;
            edit.cutSize = self.selectItem.size;

            [edit setEditCompleted:^(TUPEvaReplaceConfig_ImageOrVideo * _Nonnull config, NSString *savePath) {

                [self.navigationController popToViewController:self animated:YES];

                [self updateVideoResource:config path:savePath videoPath:self.selectItem.replaceResPath];

            }];
            [self showViewController:edit sender:nil];
            
        } else {
            //图片素材
            ImageEditViewController *edit = [[ImageEditViewController alloc] initWithNibName:nil bundle:nil];
            //输入原始图片素材
            edit.inputImage = self.selectItem.originalImage;
            edit.index = self.selectItem.itemIndex;
            edit.cutSize = self.selectItem.size;
            [edit setEditCompleted:^(NSURL * _Nonnull outputUrl) {
                [self.navigationController popToViewController:self animated:YES];
                [self updateImageResource:outputUrl];
            }];
            [self showViewController:edit sender:nil];
        }
    }
}

/**
 * 删除选中素材资源
 * @param selectItem  选中组件
 */
- (void)mutiAssetPickerSelectView:(TTMutiAssetPickSelectView *)view deleteItem:(TAEModelVideoItem *)selectItem;
{
    NSLog(@"TUEVA::删除素材");
    _selectItem = selectItem;
    if (!selectItem.asset) return;
    //移除asset
    BOOL success = [_allPicker removePHAsset:_selectItem.asset];
}

#pragma mark - TuPanelTabbarDelegate
- (void)panelBar:(TuPanelBar *)bar didSwitchFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;
{
    switch (toIndex) {
        case 0:
            self.allPicker.assetMediaType = TTAssetMediaTypeAll;
            break;
        case 1:
            self.allPicker.assetMediaType = TTAssetMediaTypeVideo;
            break;
        default:
            self.allPicker.assetMediaType = TTAssetMediaTypeImage;
            break;
    }
}
/**
 * 更新图片资源
 * @param fileUrl 图片路径
 */
- (void)updateImageResource:(NSURL *)fileUrl
{
    NSString *selectedPath = [fileUrl.absoluteString componentsSeparatedByString:@"file://"].lastObject;

    __weak typeof(self)weakSelf = self;
    
    [TAEModelMediator requestImageWith:selectedPath resultHandle:^(UIImage * _Nonnull reslut) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
//            [weakSelf.evaMediator addTempFilePath:fileUrl.path];
//
//            weakSelf.selectItem.replaceResPath = selectedPath;
//            weakSelf.selectItem.isReplace = YES;
//            weakSelf.selectItem.isSelectVideo = NO;
//
//            weakSelf.selectItem.thumbnail = reslut;
//
//            [weakSelf.evaMediator replaceVideoItem:self.selectItem];
//            [weakSelf.pickerSelectView reloadData];
            
            [weakSelf updateImageResource:fileUrl image:reslut];
        });
        
    }];
}
/**
 * 更新图片资源
 * @param fileUrl 图片路径
 * @param image 封面图
 */
- (void)updateImageResource:(NSURL *)fileUrl image:(UIImage *)image
{
    NSString *selectedPath = [fileUrl.absoluteString componentsSeparatedByString:@"file://"].lastObject;
    [self.evaMediator addTempFilePath:fileUrl.path];
    self.selectItem.replaceResPath = selectedPath;
    self.selectItem.isReplace = YES;
    self.selectItem.isSelectVideo = NO;
    self.selectItem.thumbnail = image;
    BOOL success = [self.evaMediator replaceVideoItem:self.selectItem];
    if (success) {
        [self.pickerSelectView reloadData];
    }
}

/**
 * 更新视频图片资源
 * @param config 视频裁剪配置
 * @param path 视频裁剪后路径
 * @param videoPath 源视频路径（非file:// 开头地址）
 */
- (void)updateVideoResource:(TUPEvaReplaceConfig_ImageOrVideo *)config path:(NSString *)path videoPath:(NSString *)videoPath
{
    NSString *selectedPath = [path componentsSeparatedByString:@"file://"].lastObject;
    __weak typeof(self)weakSelf = self;
    
    [TAEModelMediator requestVideoImageWith:selectedPath cropRect:config.crop resultHandle:^(UIImage * _Nonnull reslut) {
        
//        [weakSelf.evaMediator addTempFilePath:selectedPath];
//        NSLog(@"TUEVA:视频图片获取完成");
//        weakSelf.selectItem.isReplace = YES;
//        weakSelf.selectItem.isSelectVideo = YES;
//        weakSelf.selectItem.replaceResPath = selectedPath;
//        weakSelf.selectItem.thumbnail = reslut;
//        if (config) {
//            weakSelf.selectItem.crop = config.crop;
//            weakSelf.selectItem.start = config.start;
//            weakSelf.selectItem.duration = config.duration;
//            weakSelf.selectItem.maxSide = config.maxSide;
//        }
//
//        [weakSelf.evaMediator replaceVideoItem:self.selectItem];
//        [weakSelf.pickerSelectView reloadData];
        [weakSelf updateVideoResource:config path:path videoPath:selectedPath image:reslut];
        [TuPopupProgress dismiss];
    }];
}
/**
 * 更新视频图片资源
 * @param config 视频裁剪配置
 * @param path 视频裁剪后路径
 * @param videoPath 源视频路径（非file:// 开头地址）
 * @param image 封面图
 */
- (void)updateVideoResource:(TUPEvaReplaceConfig_ImageOrVideo *)config path:(NSString *)path videoPath:(NSString *)videoPath image:(UIImage *)image
{
    if (path) {
        NSString *selectedPath = [path componentsSeparatedByString:@"file://"].lastObject;
        [self.evaMediator addTempFilePath:selectedPath];
    }
    
    self.selectItem.isReplace = YES;
    self.selectItem.isSelectVideo = YES;
    self.selectItem.replaceResPath = videoPath;
    self.selectItem.thumbnail = image;
    if (config) {
        self.selectItem.crop = config.crop;
        self.selectItem.start = config.start;
        self.selectItem.duration = config.duration;
        self.selectItem.maxSide = config.maxSide;
    }
    
    [self.evaMediator replaceVideoItem:self.selectItem];
    [self.pickerSelectView reloadData];
}

#pragma mark - MultiPickerDelegate

/**
 * 点击选中按钮事件回调
 * @param picker 多视频选择器
 * @param indexPath 点击的 NSIndexPath 对象
 * @param phAsset 对应的 PHAsset 对象
 */
- (BOOL)picker:(TTMultiAssetPicker *)picker didSelectButtonItemWithIndexPath:(NSIndexPath *)indexPath phAsset:(PHAsset *)phAsset coverImage:(nonnull UIImage *)coverImage;
{
    NSLog(@"TUEVA:单选按钮点击回调");
    
    if (phAsset.mediaType == PHAssetMediaTypeVideo && _selectItem.type == TAEModelAssetType_Image) {
        [TuPopupProgress showErrorWithStatus:@"只允许选择图片素材"];
        return NO;
    }
    if (phAsset.mediaType == PHAssetMediaTypeImage && _selectItem.type == TAEModelAssetType_Video) {
        [TuPopupProgress showErrorWithStatus:@"只允许选择视频素材"];
        return NO;
    }
    
    if (self.pickerSelectView.selectCount == self.maxSelectCount) {
        
        [TuPopupProgress showSuccessWithStatus:@"已达到素材添加上限"];
        return NO;
    }
    
    self.selectItem.asset = phAsset;
    __weak typeof(self)weakSelf = self;
    __weak typeof(self.selectItem)weakAsset = self.selectItem;
    [self requestAVAsset:phAsset completion:^(PHAsset *inputPhAsset, NSObject *returnValue) {
       
        dispatch_async(dispatch_get_main_queue(), ^{
            //选择图片资源
            if (inputPhAsset.mediaType == PHAssetMediaTypeImage) {
                UIImage *image = coverImage;
                //保存原始的图片素材
                weakSelf.selectItem.originalImage = image;
                //获取沙盒图片路径
                [TAEModelMediator requestImagePathWith:image imageIndex:weakAsset.itemIndex resultHandle:^(NSString * _Nonnull filePath) {
                    if (!filePath) return;
                    [weakSelf updateImageResource:[NSURL fileURLWithPath:filePath] image:image];
                }];
            } else {
                AVURLAsset *asset = (AVURLAsset *)returnValue;
//                NSLog(@"TUEVA::视频宽高 == %@", NSStringFromCGSize(asset.naturalSize));
                NSString *videoPath = asset.URL.absoluteString;

                [weakSelf updateVideoResource:nil path:nil videoPath:videoPath image:coverImage];
            }
        });
    }];
    return YES;
}

/**
 * 点击单元格事件回调
 * @param picker 多视频选择器
 * @param indexPath 点击的 NSIndexPath 对象
 * @param phAsset 对应的 PHAsset 对象
 */
- (void)picker:(TTMultiAssetPicker *)picker didTapItemWithIndexPath:(NSIndexPath *)indexPath phAsset:(PHAsset *)phAsset coverImage:(nonnull UIImage *)coverImage {
    
    self.selectItem.asset = phAsset;
    __weak typeof(self)weakSelf = self;
    __weak typeof(self.selectItem)weakAsset = self.selectItem;
    [self requestAVAsset:phAsset completion:^(PHAsset *inputPhAsset, NSObject *returnValue) {
       
        dispatch_async(dispatch_get_main_queue(), ^{
            //选择图片资源
            if (inputPhAsset.mediaType == PHAssetMediaTypeImage) {
                ImageEditViewController *controller = [[ImageEditViewController alloc] initWithNibName:nil bundle:nil];
                controller.inputImage = (UIImage *)returnValue;
                controller.cutSize = weakAsset.size;
                controller.index = weakAsset.itemIndex;
                [controller setEditCompleted:^(NSURL * _Nonnull outputUrl) {
                   
                    [weakSelf.navigationController popToViewController:weakSelf animated:YES];
                    NSLog(@"TUEVA:图片选择路径==%@", outputUrl.path);
                    [weakSelf updateImageResource:outputUrl];
                }];
                [picker showViewController:controller sender:nil];
                
            } else if (inputPhAsset.mediaType == PHAssetMediaTypeVideo) {
                
                VideoEditViewController *controller = [[VideoEditViewController alloc] initWithNibName:nil bundle:nil];
                AVURLAsset *assets = (AVURLAsset *)returnValue;
                NSLog(@"TUEVA:视频输出路径 === %@", assets.URL);
                controller.filePath = [assets.URL.absoluteString componentsSeparatedByString:@"file://"].lastObject;
                controller.inputAssets = @[(AVAsset *)returnValue];
                controller.cutSize = weakAsset.size;
                controller.durationTime = weakAsset.endTime - weakAsset.startTime;
                [controller setEditCompleted:^(TUPEvaReplaceConfig_ImageOrVideo * _Nonnull config, NSString * _Nonnull savePath) {
                   
                    [weakSelf.navigationController popToViewController:weakSelf animated:YES];
                    NSLog(@"TUEVA:视频选择路径==%@", savePath);
                    [weakSelf updateVideoResource:config path:savePath videoPath:assets.URL.absoluteString];
                }];
                [picker showViewController:controller sender:nil];
            }
        });
    }];
}

/**
 请求 PHAsset
 
 @param phAsset PHAsset 文件对象
 @param completion 完成后的操作
 */
- (void)requestAVAsset:(PHAsset *)phAsset completion:(void (^)(PHAsset *inputPhAsset, NSObject *returnValue))completion {
    
    if (phAsset.mediaType == PHAssetMediaTypeImage) {
        
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.networkAccessAllowed = YES;
        options.synchronous = YES;
        // 配置请求
        options.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
            if (progress == 1.0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [TuPopupProgress dismiss];
                });
            } else {
                [TuPopupProgress showProgress:progress status:@"iCloud 同步中"];
            }
        };
        
        CGSize outputSize = [self safeVideoSize:CGSizeMake(phAsset.pixelWidth, phAsset.pixelWidth)];
        
        [[PHImageManager defaultManager] requestImageForAsset:phAsset targetSize:outputSize contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            if (completion) completion(phAsset, result);
        }];
        
    } else {
        
        PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
        options.networkAccessAllowed = YES;
        options.deliveryMode = PHVideoRequestOptionsDeliveryModeMediumQualityFormat;
        // 配置请求
        options.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
            
            if (progress == 1.0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [TuPopupProgress dismiss];
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [TuPopupProgress showProgress:progress status:@"iCloud 同步中"];
                });
                
            }
            
        };
        
        //NSLog(@"TUEVA::原视频size===%@", NSStringFromCGSize(CGSizeMake(phAsset.pixelWidth, phAsset.pixelHeight)));
        CGFloat minSide = MIN(phAsset.pixelWidth, phAsset.pixelHeight);
//        if (minSide <= 540) {
//
            [[PHImageManager defaultManager] requestAVAssetForVideo:phAsset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {

                if (completion) completion(phAsset, asset);
            }];
//
//        } else {
//
//            [TuPopupProgress showWithStatus:@"处理中.."];
//
//            [[PHImageManager defaultManager] requestExportSessionForVideo:phAsset options:options exportPreset:AVAssetExportPreset960x540 resultHandler:^(AVAssetExportSession * _Nullable exportSession, NSDictionary * _Nullable info) {
//
//                TTDirectorMediator *mediator = [[TTDirectorMediator alloc] init];
//                NSString *filePath = [mediator generateTempFile];
//                exportSession.outputURL = [NSURL fileURLWithPath:filePath];
//                exportSession.shouldOptimizeForNetworkUse = YES;
//                exportSession.outputFileType = AVFileTypeMPEG4;
//                [exportSession exportAsynchronouslyWithCompletionHandler:^{
//
//                    if (exportSession.status == AVAssetExportSessionStatusCompleted) {
//                        AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:filePath]];
////                        NSLog(@"TUEVA::压缩后的视频路径==%@", filePath);
//                        [self.evaMediator addTempFilePath:filePath];
////                        NSLog(@"TUEVA::导出后的视频路径==%@", [NSURL fileURLWithPath:filePath]);
//                        if (completion) completion(phAsset, asset);
//
//                    }
//                }];
//            }];
//        }
    }
}

/**
 根据 videoSize 获取安全的size
 
 @param videoSize videoSize
 @return CGSize
 */
- (CGSize)safeVideoSize:(CGSize)videoSize
{
    /** 验证最小边界，如果大于1080降低分辨率 */
    CGFloat minSide = MIN(videoSize.width, videoSize.height);
    
    // 如果最小边大于 1080 则降低分辨率到1080
    if (minSide > lsqMaxOutputVideoSizeSide)
    {
        CGFloat scale =  lsqMaxOutputVideoSizeSide / minSide;
         return CGSizeMake(videoSize.width * scale, videoSize.height * scale);
    }
    
    return videoSize;
}

#pragma mark - setter getter

- (void)setEvaMediator:(TAEModelMediator *)evaMediator
{
    _evaMediator = evaMediator;
}

- (void)setFilePath:(NSString *)filePath
{
    _filePath = filePath;
}

- (TTMultiAssetPicker *)allPicker
{
    if (!_allPicker) {
        _allPicker = [TTMultiAssetPicker picker];
        _allPicker.fetchMediaTypes = @[@(PHAssetMediaTypeVideo), @(PHAssetMediaTypeImage)];
        _allPicker.delegate = self;
        _allPicker.disableMultipleSelection = NO;
        _allPicker.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
        
    }
    return _allPicker;
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
