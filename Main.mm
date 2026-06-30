#import <Foundation/Foundation.h>
#import <vector>
#import <string>
#import <fstream>

// Đường dẫn Sandbox Minecraft iOS
NSString* GetMinecraftPath() {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
}

// --- XỬ LÝ TAB GENERAL (options.txt) ---
void LoadOptionsTxt(char* buffer, size_t max_size) {
    NSString* path = [GetMinecraftPath() stringByAppendingPathComponent:@"games/com.mojang/minecraftpe/options.txt"];
    NSError* error = nil;
    NSString* content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    if (!error) {
        snprintf(buffer, max_size, "%s", [content UTF8String]);
    } else {
        snprintf(buffer, max_size, "Không thể tải options.txt hoặc file không tồn tại.");
    }
}

void SaveOptionsTxt(const char* content) {
    NSString* path = [GetMinecraftPath() stringByAppendingPathComponent:@"games/com.mojang/minecraftpe/options.txt"];
    NSString* newContent = [NSString stringWithUTF8String:content];
    [newContent writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

// --- XỬ LÝ TAB WORLD (level.dat NBT) ---
std::vector<uint8_t> worldDataBuffer;
uint32_t bedrockHeaderVersion = 2; // Mặc định thường là 2 hoặc 4

// Hàm tìm vị trí của một Tag cụ thể trong chuỗi NBT thô
// Cấu trúc Bedrock NBT: [Type (1B)] [Name Length (2B)] [Name String]
ptrdiff_t FindNBTTag(const std::vector<uint8_t>& buffer, const std::string& tagName) {
    auto it = std::search(buffer.begin(), buffer.end(), tagName.begin(), tagName.end());
    if (it != buffer.end()) {
        return std::distance(buffer.begin(), it);
    }
    return -1; // Không tìm thấy
}

bool LoadLevelDat(const char* worldFolder) {
    NSString* path = [GetMinecraftPath() stringByAppendingFormat:@"/games/com.mojang/minecraftWorlds/%s/level.dat", worldFolder];
    std::ifstream file([path UTF8String], std::ios::binary);
    if (!file.is_open()) return false;

    // 1. Đọc Header 8-byte đặc trưng của Bedrock
    uint32_t nbtLength = 0;
    file.read(reinterpret_cast<char*>(&bedrockHeaderVersion), 4);
    file.read(reinterpret_cast<char*>(&nbtLength), 4);

    // 2. Đọc phần data NBT thô dựa trên nbtLength
    worldDataBuffer.resize(nbtLength);
    file.read(reinterpret_cast<char*>(worldDataBuffer.data()), nbtLength);
    file.close();
    return true;
}

// Hàm đọc nhanh giá trị 1-byte (như kiểu bool: cheatsEnabled, commandsEnabled)
bool ReadByteTag(const std::string& tagName, uint8_t& outValue) {
    ptrdiff_t offset = FindNBTTag(worldDataBuffer, tagName);
    if (offset == -1) return false;
    
    // Vị trí giá trị = Vị trí tên tag + Độ dài tên tag
    size_t valuePos = offset + tagName.length();
    if (valuePos < worldDataBuffer.size()) {
        outValue = worldDataBuffer[valuePos];
        return true;
    }
    return false;
}

// Hàm sửa nhanh giá trị 1-byte và lưu lại vào buffer
bool WriteByteTag(const std::string& tagName, uint8_t newValue) {
    ptrdiff_t offset = FindNBTTag(worldDataBuffer, tagName);
    if (offset == -1) return false;

    size_t valuePos = offset + tagName.length();
    if (valuePos < worldDataBuffer.size()) {
        worldDataBuffer[valuePos] = newValue;
        return true;
    }
    return false;
}

bool SaveLevelDat(const char* worldFolder) {
    NSString* path = [GetMinecraftPath() stringByAppendingFormat:@"/games/com.mojang/minecraftWorlds/%s/level.dat", worldFolder];
    std::ofstream file([path UTF8String], std::ios::binary);
    if (!file.is_open()) return false;

    // Tính toán lại độ dài NBT mới sau khi chỉnh sửa
    uint32_t nbtLength = static_cast<uint32_t>(worldDataBuffer.size());

    // Ghi lại Header 8-byte
    file.write(reinterpret_cast<const char*>(&bedrockHeaderVersion), 4);
    file.write(reinterpret_cast<const char*>(&nbtLength), 4);

    // Ghi dữ liệu NBT
    file.write(reinterpret_cast<const char*>(worldDataBuffer.data()), nbtLength);
    file.close();
    return true;
}