#import <UIKit/UIKit.h>
#import "GUI.h"

// Gọi các hàm xử lý từ Main.mm
extern void LoadOptionsTxt(char* buffer, size_t max_size);
extern void SaveOptionsTxt(const char* content);
extern bool LoadLevelDat(const char* worldFolder);
extern bool SaveLevelDat(const char* worldFolder);
extern bool ReadByteTag(const std::string& tagName, uint8_t& outValue);
extern bool WriteByteTag(const std::string& tagName, uint8_t newValue);

@interface BedrockMenuManager : NSObject
+ (instancetype)sharedInstance;
- (void)setupMenuButton;
@end

@implementation BedrockMenuManager {
    UIButton *_menuButton;
}

+ (instancetype)sharedInstance {
    static BedrockMenuManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[BedrockMenuManager alloc] init];
    });
    return instance;
}

- (void)setupMenuButton {
    // Chạy trên Main Thread để tránh crash UI
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self->_menuButton) return; // Đã tạo rồi thì bỏ qua

        UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
        if (!keyWindow) return;

        // Tạo nút "..." với kích thước 45x45
        self->_menuButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [self->_menuButton setTitle:@"..." forState:UIControlStateNormal];
        self->_menuButton.titleLabel.font = [UIFont boldSystemFontOfSize:24];
        self->_menuButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        [self->_menuButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self->_menuButton.layer.cornerRadius = 8;
        
        // Cấu hình Auto Layout để TỰ ĐỘNG XOAY theo màn hình (Bám góc phải trên cùng)
        self->_menuButton.translatesAutoresizingMaskIntoConstraints = NO;
        [keyWindow addSubview:self->_menuButton];
        
        [NSLayoutConstraint activateConstraints:@[
            [self->_menuButton.topAnchor constraintEqualToAnchor:keyWindow.safeAreaLayoutGuide.topAnchor constant:10],
            [self->_menuButton.trailingAnchor constraintEqualToAnchor:keyWindow.safeAreaLayoutGuide.trailingAnchor constant:-10],
            [self->_menuButton.widthAnchor constraintEqualToConstant:45],
            [self->_menuButton.heightAnchor constraintEqualToConstant:45]
        ]];

        [self->_menuButton addTarget:self action:@selector(buttonTapped) forControlEvents:UIControlEventTouchUpInside];
    });
}

- (void)buttonTapped {
    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    if (!rootVC) return;

    // Tạo Menu lựa chọn nhanh cho Tây ba lô và người Việt
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"BedrockNBT-LITE v0.1.0" 
                                                                   message:@"Chọn tính năng bạn muốn chỉnh sửa" 
                                                            preferredStyle:UIAlertControllerStyleActionSheet];

    // --- MỤC CHUNG (GENERAL) ---
    UIAlertAction *generalAction = [UIAlertAction actionWithTitle:@"General (Chung - options.txt)" 
                                                            style:UIAlertActionStyleDefault 
                                                          handler:^(UIAlertAction * action) {
        [self showGeneralEditorFrom:rootVC];
    }];

    // --- MỤC WORLD ---
    UIAlertAction *worldAction = [UIAlertAction actionWithTitle:@"World Editor (level.dat)" 
                                                          style:UIAlertActionStyleDefault 
                                                        handler:^(UIAlertAction * action) {
        [self showWorldEditorFrom:rootVC];
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Đóng (Close)" style:UIAlertActionStyleCancel handler:nil];

    [alert addAction:generalAction];
    [alert addAction:worldAction];
    [alert addAction:cancelAction];

    // Hỗ trợ hiển thị trên iPad (không bị crash ActionSheet)
    alert.popoverPresentationController.sourceView = self->_menuButton;
    alert.popoverPresentationController.sourceRect = self->_menuButton.bounds;

    [rootVC presentViewController:alert animated:YES completion:nil];
}

// Giao diện sửa options.txt
- (void)showGeneralEditorFrom:(UIViewController *)rootVC {
    UIAlertController *editor = [UIAlertController alertControllerWithTitle:@"General Settings" message:@"options.txt" preferredStyle:UIAlertControllerStyleAlert];
    
    [editor addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        char buf[4096] = {0};
        LoadOptionsTxt(buf, sizeof(buf));
        textField.text = [NSString stringWithUTF8String:buf];
    }];
    
    UIAlertAction *save = [UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *input = editor.textFields.firstObject;
        SaveOptionsTxt([input.text UTF8String]);
    }];
    
    [editor addAction:save];
    [editor addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [rootVC presentViewController:editor animated:YES completion:nil];
}

// Giao diện sửa World (Gian lận / Lệnh)
- (void)showWorldEditorFrom:(UIViewController *)rootVC {
    UIAlertController *worldPrompt = [UIAlertController alertControllerWithTitle:@"World Editor" message:@"Nhập tên thư mục World" preferredStyle:UIAlertControllerStyleAlert];
    
    [worldPrompt addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Ví dụ: MyWorldFolder";
    }];
    
    UIAlertAction *load = [UIAlertAction actionWithTitle:@"Load & Chỉnh sửa" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *input = worldPrompt.textFields.firstObject;
        NSString *folderName = input.text;
        
        if (LoadLevelDat([folderName UTF8String])) {
            uint8_t cheats = 0, commands = 0;
            ReadByteTag("cheatsEnabled", cheats);
            ReadByteTag("commandsEnabled", commands);
            
            // Hiện bảng bật tắt
            UIAlertController *toggleMenu = [UIAlertController alertControllerWithTitle:@"Tùy chỉnh World" message:folderName preferredStyle:UIAlertControllerStyleAlert];
            
            [toggleMenu addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Bật Cheats: %@", cheats ? @"ĐANG BẬT" : @"ĐANG TẮT"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                WriteByteTag("cheatsEnabled", cheats ? 0 : 1);
                SaveLevelDat([folderName UTF8String]);
            }]];
            
            [toggleMenu addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Bật Commands: %@", commands ? @"ĐANG BẬT" : @"ĐANG TẮT"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                WriteByteTag("commandsEnabled", commands ? 0 : 1);
                SaveLevelDat([folderName UTF8String]);
            }]];
            
            [toggleMenu addAction:[UIAlertAction actionWithTitle:@"Xong" style:UIAlertActionStyleCancel handler:nil]];
            [rootVC presentViewController:toggleMenu animated:YES completion:nil];
        }
    }];
    
    [worldPrompt addAction:load];
    [worldPrompt addAction:[UIAlertAction actionWithTitle:@"Hủy" style:UIAlertActionStyleCancel handler:nil]];
    [rootVC presentViewController:worldPrompt animated:YES completion:nil];
}
@end

// Hàm kích hoạt giao diện từ Tweak/Hook bên ngoài gọi vào
void RenderBedrockNBTLite() {
    [[BedrockMenuManager sharedInstance] setupMenuButton];
}