//
//  EpitomeRecordViewController.m
//  FunSDKDemo
//
//  Created by feimy on 2024/6/17.
//  Copyright © 2024 feimy. All rights reserved.
//

#import "EpitomeRecordViewController.h"
#import "EpitomeRecordConfig.h"
#import "ItemTableviewCell.h"
#import "DateSelectView.h"
#import "NSDate+TimeCategory.h"

@interface EpitomeRecordViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, EpitomeRecordConfigDelegate>

@property(nonatomic, strong) EpitomeRecordConfig *epitomeRecordConfig;
@property(nonatomic, strong) NSMutableArray *epitomeRecordArray;
@property (nonatomic, strong) UITextField *nameTextField;
@property (nonatomic, strong) UITableView *recordTableView;
@property (nonatomic, strong) UIDatePicker *picker;

@end

@implementation EpitomeRecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // TS("Custom_example") 自定义时间段
    self.epitomeRecordArray = @[TS("EpitomeRecord_Enable"), TS("EpitomeRecord_Interval"), TS("EpitomeRecord_StartTime"), TS("EpitomeRecord_EndTime")];
    [self configSubView];
    //请求缩影配置
    [self getEpitomeRecordConfig];
    
    // 添加一个点击手势识别器
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideDatePicker)];
    tapGesture.cancelsTouchesInView = NO; // 设置为需要点击空白处才触发
    [self.view addGestureRecognizer:tapGesture];
}

- (void)viewWillDisappear:(BOOL)animated{
    //有加载状态、则取消加载
    if ([SVProgressHUD isVisible]){
        [SVProgressHUD dismiss];
    }
}

//MARK: - 界面和数据初始化
- (void)configSubView {
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave  target:self action:@selector(saveConfig)];
    self.navigationItem.rightBarButtonItem = rightButton;
    [self.view addSubview:self.recordTableView];
    [self.view addSubview: self.picker];
}

//MARK: - 获取缩影配置
- (void)getEpitomeRecordConfig{
    [SVProgressHUD show];
    [self.epitomeRecordConfig getEpitomeRecordConfig];
}

//MARK: - 获取缩影配置回调
- (void)getEpitomeRecordConfigResult:(NSInteger)result{
    if (result >= 0) {
        [self.recordTableView reloadData];
        [SVProgressHUD dismiss];
    }else{
        [MessageUI ShowErrorInt:(int)result];
    }
}

//MARK: - 保存缩影录像配置
- (void)saveConfig{
    [SVProgressHUD show];
    [self.epitomeRecordConfig saveEpitomeRecordConfig];
}

//MARK: - 保存缩影录像配置回调
- (void)saveEpitomeRecordConfigResult:(NSInteger)result{
    if (result >= 0) {
        [SVProgressHUD dismiss];
    }else{
        [MessageUI ShowErrorInt:(int)result];
    }
}

#pragma mark - tableView代理方法
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.epitomeRecordArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    int section = indexPath.section;
    ItemTableviewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ItemTableviewCell"];
    cell = [[ItemTableviewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ItemTableviewCell"];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    NSString *title = [self.epitomeRecordArray objectAtIndex:indexPath.row];
    cell.textLabel.text = title;
    if ([title isEqualToString: TS("EpitomeRecord_Enable")]) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        [cell setCellType:cellTypeSwitch];
        cell.mySwitch.on = [self.epitomeRecordConfig getEpitomeRecordEnable];
        cell.statusSwitchClicked = ^(BOOL on, int section, int row) {
            [self.epitomeRecordConfig setEpitomeRecordEnable:on];
        };
    }else if ([title isEqualToString: TS("EpitomeRecord_Interval")]){
        cell.Labeltext.text = [NSString stringWithFormat: @"%d", [self.epitomeRecordConfig getEpitomeRecordInterval]];
    }else if ([title isEqualToString: TS("EpitomeRecord_StartTime")]){
        cell.Labeltext.text = [self.epitomeRecordConfig getEpitomeReconrdStartTime];
    }else if ([title isEqualToString: TS("EpitomeRecord_EndTime")]){
        cell.Labeltext.text = [self.epitomeRecordConfig getEpitomeReconrdEndTime];
    }
    else if ([title isEqualToString:TS("Custom_example")]){   //自定义时间段（与开始时间 结束时间冲突可能会冲突）
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    int section = indexPath.section;
    NSString *titleStr = self.epitomeRecordArray[indexPath.row];
        
    if([titleStr isEqualToString: TS("EpitomeRecord_Interval")]){
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:TS("EpitomeRecord_Interval") message:@"" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:TS("Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        }];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:TS("OK") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if (self.nameTextField.text.length == 0){
                [SVProgressHUD showErrorWithStatus:TS("EpitomeRecord_Interval_empty") duration:1.0];
                return;
            }
            NSIndexPath *currentPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section];
            //找到对应的cell
            ItemTableviewCell *currentCell = [self.recordTableView cellForRowAtIndexPath:currentPath];
            currentCell.Labeltext.text = self.nameTextField.text;
            [self.epitomeRecordConfig setEpitomeRecordInterval: [currentCell.Labeltext.text intValue]];
        }];
            
        [alertController addAction:okAction];
        [alertController addAction:cancelAction];
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = TS("EpitomeRecord_Interval_modify");
            self.nameTextField = textField;
            self.nameTextField.delegate = self;
        }];   
        [self presentViewController:alertController animated:YES completion:nil];
    }else if ([titleStr isEqualToString: TS("EpitomeRecord_StartTime")]){
        NSString *startTime = [self.epitomeRecordConfig getEpitomeReconrdStartTime];
        if (startTime == nil) {
            self.picker.date = [NSDate date];
        }else{
            self.picker.date = [NSDate dateFromString:startTime format:TimeFormatter];
        }
        self.picker.tag = 100;
        [self showDatePicker];
    }else if ([titleStr isEqualToString: TS("EpitomeRecord_EndTime")]){
        NSString *endTime = [self.epitomeRecordConfig getEpitomeReconrdEndTime];
        if (endTime == nil) {
            self.picker.date = [NSDate date];
        }else{
            self.picker.date = [NSDate dateFromString:endTime format:TimeFormatter];
        }
        self.picker.tag = 200;
        [self showDatePicker];
    }else if ([titleStr isEqualToString:TS("Custom_example")]){  //自定义时间段（与开始时间 结束时间冲突可能会冲突）
        [self.epitomeRecordConfig setEpitomeReconrdTimeSection];
    }
}

//MARK: - UIUIDatePicker 事件
- (void)changeValue:(UIDatePicker*)datePicker {
    if (self.picker.tag == 100) {
        [self.epitomeRecordConfig setEpitomeReconrdStartTime:[NSDate datestrFromDate:datePicker.date withDateFormat:TimeFormatter]];
        [self.recordTableView reloadData];
        
    }else if (self.picker.tag == 200) {
        [self.epitomeRecordConfig setEpitomeReconrdEndTime:[NSDate datestrFromDate:datePicker.date withDateFormat:TimeFormatter]];
        [self.recordTableView reloadData];
    }
}

- (void)showDatePicker {
    // 显示datePicker
    self.picker.hidden = NO;
}

- (void)hideDatePicker {
    // 隐藏datePicker
    self.picker.hidden = YES;
}

- (UITableView *)recordTableView {
    if (!_recordTableView) {
        _recordTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight) style:UITableViewStylePlain];
        _recordTableView.delegate = self;
        _recordTableView.dataSource = self;
        [_recordTableView registerClass:[ItemTableviewCell class] forCellReuseIdentifier:@"ItemTableviewCell"];
    }
    return _recordTableView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (EpitomeRecordConfig *)epitomeRecordConfig{
    if(!_epitomeRecordConfig){
        _epitomeRecordConfig = [[EpitomeRecordConfig alloc] init];
        _epitomeRecordConfig.epConfigDelegate = self;
    }
    return _epitomeRecordConfig;
}

- (NSMutableArray *)epitomeRecordArray{
    if (!_epitomeRecordArray) {
        _epitomeRecordArray = [[NSMutableArray alloc] initWithCapacity: 0];
    }
    return _epitomeRecordArray;
}

- (UIDatePicker *)picker{
    if (!_picker) {
        _picker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, ScreenHeight-300, ScreenWidth, 160)];
        //设置类型
        _picker.datePickerMode = UIDatePickerModeDateAndTime;
        //设置日历
        _picker.calendar = [NSCalendar currentCalendar];
        //设置设备的时区
        _picker.timeZone = [NSTimeZone defaultTimeZone];
        //设置事件
        [_picker addTarget:self action:@selector(changeValue:) forControlEvents:UIControlEventValueChanged];
        _picker.hidden = YES;
    }
    return _picker;
}

@end
