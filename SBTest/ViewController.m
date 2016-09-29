//
//  ViewController.m
//  SBTest
//
//  Created by shenzhenshihua on 16/9/28.
//  Copyright © 2016年 shenzhenshihua. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "CenterViewController.h"
#define kPeripheralName @"Kenshin Cui's Device" //外围设备名称
#define kServiceUUID @"C4FB2349-72FE-4CA2-94D6-1F3CB16331EE" //服务的UUID
#define kCharacteristicUUID @"6A3E4B28-522D-4B3B-82A9-D5E2004534FC" //特征的UUID

@interface ViewController ()<CBPeripheralManagerDelegate>


@property (weak, nonatomic) IBOutlet UITextView *log;


@property (nonatomic,strong) CBPeripheralManager *peripheralManger;//外围设备管理器
@property (nonatomic,strong) NSMutableArray * centeralM;
@property (nonatomic,strong) CBMutableCharacteristic * characteristicM;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
}

//创建
- (IBAction)startClick:(id)sender {
    _peripheralManger =[[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    
}

//更新
- (IBAction)reshClick:(id)sender {
    [self updateCharacteristicValue];
    
    
}

- (IBAction)jumpTO:(id)sender {
    
    CenterViewController * Center = [[CenterViewController alloc] init];
    
    [self presentViewController:Center animated:YES completion:nil];
    
    
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];

}
#pragma mark ---CBPeripheralManager代理方法


- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral{
    switch (peripheral.state) {
        case CBManagerStatePoweredOn:
            NSLog(@"已经打开设备");
            [self writeToLog:@"Ble已经打开"];
            [self setupService];
            break;
            
        default:
            NSLog(@"此设备不支持BLE或未打开蓝牙功能，无法作为外围设备.");
            [self writeToLog:@"此设备不支持BLE或未打开蓝牙功能，无法作为外围设备."];
            break;
    }


}

//外围设备添加到服务
- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error{
    if (error) {
        NSLog(@"向外围设备添加服务失败，错误详情：%@",error.localizedDescription);
        [self writeToLog:[NSString stringWithFormat:@"向外围设备添加服务失败，错误详情：%@",error.localizedDescription]];
        return;
    }
    
    NSDictionary * dict = @{CBAdvertisementDataLocalNameKey:kPeripheralName};
    
    [self.peripheralManger startAdvertising:dict];
    
    NSLog(@"向外围设备添加了服务并开始广播...");
    [self writeToLog:@"向外围设备添加了服务并开始广播..."];

}

//添加失败
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error{
    if (error) {
        NSLog(@"启动广播过程中发生错误，错误信息：%@",error.localizedDescription);
        [self writeToLog:[NSString stringWithFormat:@"启动广播过程中发生错误，错误信息：%@",error.localizedDescription]];
        return;
    }
    NSLog(@"启动广播...");
    [self writeToLog:@"启动广播..."];


}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic{
    NSLog(@"中心设备：%@ 已订阅特征：%@.",central,characteristic);
    [self writeToLog:[NSString stringWithFormat:@"中心设备：%@ 已订阅特征：%@.",central.identifier.UUIDString,characteristic.UUID]];
    //发现中心设备并存储
    if (![self.centeralM containsObject:central]) {//检查数组里面是否已经存在这个对象
        [self.centeralM addObject:central];
    }
    /*中心设备订阅成功后外围设备可以更新特征值发送到中心设备,一旦更新特征值将会触发中心设备的代理方法：
     -(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
     */
    
    //    [self updateCharacteristicValue];

}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic{


}

- (void)peripheralManager:(CBPeripheralManager *)peripheral willRestoreState:(NSDictionary *)dict{
    
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request{

}



- (NSMutableArray *)centeralM{
    if (_centeralM==nil) {
        _centeralM = [NSMutableArray array];
    }
    
    return _centeralM;

}

#pragma mark - 私有方法
//创建特征、服务并添加服务到外围设备
-(void)setupService{
    /*1.创建特征*/
    //创建特征的UUID对象
    CBUUID *characteristicUUID=[CBUUID UUIDWithString:kCharacteristicUUID];
    //特征值
    //    NSString *valueStr=kPeripheralName;
    //    NSData *value=[valueStr dataUsingEncoding:NSUTF8StringEncoding];
    //创建特征
    /** 参数
     * uuid:特征标识
     * properties:特征的属性，例如：可通知、可写、可读等
     * value:特征值
     * permissions:特征的权限
     */
    CBMutableCharacteristic *characteristicM=[[CBMutableCharacteristic alloc]initWithType:characteristicUUID properties:CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable];
    self.characteristicM=characteristicM;
    //    CBMutableCharacteristic *characteristicM=[[CBMutableCharacteristic alloc]initWithType:characteristicUUID properties:CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadable];
    //    characteristicM.value=value;
    
    /*创建服务并且设置特征*/
    //创建服务UUID对象
    CBUUID *serviceUUID=[CBUUID UUIDWithString:kServiceUUID];
    //创建服务
    CBMutableService *serviceM=[[CBMutableService alloc]initWithType:serviceUUID primary:YES];
    //设置服务的特征
    [serviceM setCharacteristics:@[characteristicM]];
    
    
    /*将服务添加到外围设备*/
    [self.peripheralManger addService:serviceM];
}
//更新特征值
-(void)updateCharacteristicValue{
    //特征值
    NSString *valueStr=[NSString stringWithFormat:@"%@ --%@",kPeripheralName,[NSDate   date]];
    NSData *value=[valueStr dataUsingEncoding:NSUTF8StringEncoding];
    //更新特征值
    [self.peripheralManger updateValue:value forCharacteristic:self.characteristicM onSubscribedCentrals:nil];
    [self writeToLog:[NSString stringWithFormat:@"更新特征值：%@",valueStr]];
}


/**
*  记录日志
*
*  @param info 日志信息
*/
-(void)writeToLog:(NSString *)info{
    self.log.text =[NSString stringWithFormat:@"%@\r\n%@",self.log.text,info];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
