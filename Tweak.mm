#import <UIKit/UIKit.h>

// Gọi hàm tạo giao diện từ file GUI.mm sang
extern void RenderBedrockNBTLite();

// Sử dụng thuộc tính constructor để dylib tự động chạy ngay khi vừa được chích vào game
__attribute__((constructor)) static void initialize_tweak() {
    // Đợi 5 giây sau khi game mở lên để đảm bảo cửa sổ chính (UIWindow) đã load xong
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        RenderBedrockNBTLite();
        NSLog(@"[BedrockNBT-LITE] Đã kích hoạt nút ... thành công!");
    });
}
