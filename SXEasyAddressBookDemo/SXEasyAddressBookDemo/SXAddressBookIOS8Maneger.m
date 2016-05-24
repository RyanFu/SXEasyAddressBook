//
//  SXAddressBookIOS8Maneger.m
//  SXEasyAddressBookDemo
//
//  Created by dongshangxian on 16/5/23.
//  Copyright © 2016年 Sankuai. All rights reserved.
//

#import "SXAddressBookIOS8Maneger.h"
#import <AddressBookUI/AddressBookUI.h>

@interface SXAddressBookIOS8Maneger ()<ABPeoplePickerNavigationControllerDelegate>

@property(nonatomic,copy) SXAddressBookChooseAction chooseAction;

@end

@implementation SXAddressBookIOS8Maneger

+ (SXAddressBookIOS8Maneger *)manager
{
    static SXAddressBookIOS8Maneger *sharedInstance = nil;
    if (!sharedInstance) {
        static dispatch_once_t once;
        dispatch_once(&once, ^{
            sharedInstance = [[self alloc] init];
        });
    }
    return sharedInstance;
}

- (void)presentPageOnTarget:(id)target chooseAction:(SXAddressBookChooseAction)action{
    self.chooseAction = action;
    ABPeoplePickerNavigationController *ppnc = [[ABPeoplePickerNavigationController alloc] init];
    ppnc.predicateForSelectionOfPerson = [NSPredicate predicateWithValue:false];
    ppnc.peoplePickerDelegate = self;
    [target presentViewController:ppnc animated:YES completion:nil];
}

- (void)askUserWithSuccess:(void (^)())success failure:(void (^)())failure
{
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
    ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error){
        if(granted){
            success();
        }else{
            failure();
        }
    });
}

- (SXAddressBookAuthStatus)getAuthStatus
{
    ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
    
    if (status == kABAuthorizationStatusNotDetermined) {
        NSLog(@"还没问呢");
        return kSXAddressBookAuthStatusNotDetermined;
    }else if (status == kABAuthorizationStatusAuthorized){
        NSLog(@"已经授权");
        return kSXAddressBookAuthStatusAuthorized;
    }else if (status == kABAuthorizationStatusRestricted){
        NSLog(@"没有授权");
        return kSXAddressBookAuthStatusRestricted;
    }else{
        NSLog(@"没有授权");
        return kSXAddressBookAuthStatusDenied;
    }
}

- (NSArray *)getPersonInfoArray
{
    ABAddressBookRef addressBook = ABAddressBookCreate();
    CFArrayRef peopleArray = ABAddressBookCopyArrayOfAllPeople(addressBook);
    CFIndex peopleCount = CFArrayGetCount(peopleArray);
    
    NSMutableArray *personArray = [NSMutableArray array];
    for (int i = 0; i < peopleCount; i++) {
        
        SXPersonInfoEntity *personEntity = [SXPersonInfoEntity new];
        
        ABRecordRef person = CFArrayGetValueAtIndex(peopleArray, i);
        NSString *lastName = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
        NSString *firstName = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
        NSLog(@"%@ %@", lastName, firstName);
        personEntity.lastname = lastName;
        personEntity.firstname = firstName;
        
        if ((lastName.length > 1) && (firstName.length > 1)) {
            personEntity.fullname = [firstName stringByAppendingString:lastName];
        }else if ((lastName.length > 1) && (firstName.length < 1)){
            personEntity.fullname = lastName;
        }else if ((lastName.length < 1) && (firstName.length > 1)){
            personEntity.fullname = firstName;
        }else{
            personEntity.fullname = @"noName";
        }
        
        ABMultiValueRef phones = ABRecordCopyValue(person, kABPersonPhoneProperty);
        CFIndex phoneCount = ABMultiValueGetCount(phones);
        
        NSString *fullPhoneStr = [NSString string];
        for (int i = 0; i < phoneCount; i++) {
            NSString *phoneLabel = (__bridge_transfer NSString *)ABMultiValueCopyLabelAtIndex(phones, i);
            NSString *phoneValue = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(phones, i);
            NSLog(@"%@ %@", phoneLabel, phoneValue);
            if (phoneValue.length > 0) {
                fullPhoneStr = [fullPhoneStr stringByAppendingString:phoneValue];
                fullPhoneStr = [fullPhoneStr stringByAppendingString:@","];
            }
        }
        if (fullPhoneStr.length > 1) {
            personEntity.phoneNumber = [fullPhoneStr substringToIndex:fullPhoneStr.length - 1];
        }
        [personArray addObject:personEntity];
        CFRelease(phones);
    }
    CFRelease(addressBook);
    CFRelease(peopleArray);
    return personArray;
}

// 当用户选中某一个联系人时会执行该方法,并且选中联系人后会直接退出控制器
- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker didSelectPerson:(ABRecordRef)person
{
    // 1.获取选中联系人的姓名
    CFStringRef lastName = ABRecordCopyValue(person, kABPersonLastNameProperty);
    CFStringRef firstName = ABRecordCopyValue(person, kABPersonFirstNameProperty);
    
    NSString *lastname = (__bridge_transfer NSString *)(lastName);
    NSString *firstname = (__bridge_transfer NSString *)(firstName);
    
    NSLog(@"%@ %@", lastname, firstname);
    
    // 2.获取选中联系人的电话号码
    // 2.1.获取所有的电话号码
    ABMultiValueRef phones = ABRecordCopyValue(person, kABPersonPhoneProperty);
    CFIndex phoneCount = ABMultiValueGetCount(phones);
    
    // 2.2.遍历拿到每一个电话号码
    for (int i = 0; i < phoneCount; i++) {
        // 2.2.1.获取电话对应的key
        NSString *phoneLabel = (__bridge_transfer NSString *)ABMultiValueCopyLabelAtIndex(phones, i);
        
        // 2.2.2.获取电话号码
        NSString *phoneValue = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(phones, i);
        
        NSLog(@"%@ %@", phoneLabel, phoneValue);
    }
    
    // 注意:管理内存
    CFRelease(phones);
}

// 当用户选中某一个联系人的某一个属性时会执行该方法,并且选中属性后会退出控制器
- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker didSelectPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
//    NSLog(@"%s", __func__);
//    NSLog(@"%@--%d---%d", person,property,identifier);
    
    ABMultiValueRef phone = ABRecordCopyValue(person, kABPersonPhoneProperty);
    long index = ABMultiValueGetIndexForIdentifier(phone,identifier);
    NSString *phoneNO = (__bridge NSString *)ABMultiValueCopyValueAtIndex(phone, index);
    
    CFStringRef lastName = ABRecordCopyValue(person, kABPersonLastNameProperty);
    CFStringRef firstName = ABRecordCopyValue(person, kABPersonFirstNameProperty);
    
    NSString *lastname = (__bridge_transfer NSString *)(lastName);
    NSString *firstname = (__bridge_transfer NSString *)(firstName);
    
    NSLog(@"%@ %@", lastname, firstname);
    NSLog(@"%@", phoneNO);
    
    SXPersonInfoEntity *personEntity = [SXPersonInfoEntity new];
    personEntity.lastname = lastname;
    personEntity.firstname = firstname;
    
    if ((lastname.length > 1) && (firstname.length > 1)) {
        personEntity.fullname = [firstname stringByAppendingString:lastname];
    }else if ((lastname.length > 1) && (firstname.length < 1)){
        personEntity.fullname = lastname;
    }else if ((lastname.length < 1) && (firstname.length > 1)){
        personEntity.fullname = firstname;
    }else{
        personEntity.fullname = @"noName";
    }
    
    personEntity.phoneNumber = phoneNO;
    self.chooseAction(personEntity);
}


@end
