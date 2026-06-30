#import "GUI.h"
#import <vector>
#import <string>

// Khai báo lại các hàm logic từ Main.mm để gọi qua lại
void LoadOptionsTxt(char* buffer, size_t max_size);
void SaveOptionsTxt(const char* content);
bool LoadLevelDat(const char* worldFolder);
bool SaveLevelDat(const char* worldFolder);
bool ReadByteTag(const std::string& tagName, uint8_t& outValue);
bool WriteByteTag(const std::string& tagName, uint8_t newValue);

static bool show_menu = false;
static int active_tab = 0;
static char options_buffer[8192] = "";
static char current_world_folder[128] = "MyWorldFolder"; // Thư mục world đang chọn

// Biến trạng thái để hiển thị lên UI
static uint8_t cheats_val = 0;
static uint8_t commands_val = 0;
static bool is_world_loaded = false;

void RenderBedrockNBTLite() {
    // Tự động lấy kích thước hiển thị thực tế (Xử lý xoay màn hình linh hoạt)
    ImGuiIO& io = ImGui::GetIO();
    float screen_width = io.DisplaySize.x;

    // Đặt nút "..." ở góc phải trên cùng, cách lề 50px chống lẹm tai thỏ/đục lỗ
    ImGui::SetNextWindowPos(ImVec2(screen_width - 70.0f, 30.0f), ImGuiCond_Always);
    ImGui::Begin("TriggerOverlay", NULL, ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoMove | ImGuiWindowFlags_NoBackground);
    
    if (ImGui::Button("...", ImVec2(45, 45))) {
        show_menu = !show_menu;
    }
    ImGui::End();

    // Menu chính hiển thị khi bấm nút "..."
    if (show_menu) {
        ImGui::SetNextWindowSize(ImVec2(450, 320), ImGuiCond_FirstUseEver);
        if (ImGui::Begin("BedrockNBT-LITE v0.1.0", &show_menu, ImGuiWindowFlags_NoCollapse)) {
            
            // Render Tabs
            if (ImGui::Button("General (Chung)", ImVec2(150, 0))) active_tab = 0;
            ImGui::SameLine();
            if (ImGui::Button("World Editor", ImVec2(150, 0))) active_tab = 1;
            
            ImGui::Separator();

            if (active_tab == 0) {
                // --- TAB GENERAL (Cho cả người Việt và Tây ba lô) ---
                ImGui::Text("Edit Configuration (options.txt):");
                
                if (ImGui::Button("Load options.txt")) {
                    LoadOptionsTxt(options_buffer, sizeof(options_buffer));
                }
                ImGui::SameLine();
                if (ImGui::Button("Save Changes")) {
                    SaveOptionsTxt(options_buffer);
                }

                ImGui::InputTextMultiline("##options_edit", options_buffer, IM_ARRAYSIZE(options_buffer), ImVec2(-FLT_MIN, -FLT_MIN));
            } 
            else if (active_tab == 1) {
                // --- TAB WORLD EDITOR ---
                ImGui::InputText("World Folder Name", current_world_folder, IM_ARRAYSIZE(current_world_folder));
                
                if (ImGui::Button("Load World level.dat")) {
                    if (LoadLevelDat(current_world_folder)) {
                        is_world_loaded = true;
                        ReadByteTag("cheatsEnabled", cheats_val);
                        ReadByteTag("commandsEnabled", commands_val);
                    } else {
                        is_world_loaded = false;
                    }
                }

                ImGui::Separator();

                if (is_world_loaded) {
                    ImGui::TextColored(ImVec4(0, 1, 0, 1), "World Loaded Successfully!");

                    // Checkbox cho Cheats
                    bool c_bool = (cheats_val == 1);
                    if (ImGui::Checkbox("Allow Cheats (Gian lận)", &c_bool)) {
                        cheats_val = c_bool ? 1 : 0;
                        WriteByteTag("cheatsEnabled", cheats_val);
                    }

                    // Checkbox cho Commands
                    bool cmd_bool = (commands_val == 1);
                    if (ImGui::Checkbox("Commands Enabled (Lệnh)", &cmd_bool)) {
                        commands_val = cmd_bool ? 1 : 0;
                        WriteByteTag("commandsEnabled", commands_val);
                    }

                    ImGui::Dummy(ImVec2(0, 20));
                    if (ImGui::Button("Save & Inject level.dat", ImVec2(-FLT_MIN, 40))) {
                        if (SaveLevelDat(current_world_folder)) {
                            // Thành công
                        }
                    }
                } else {
                    ImGui::TextColored(ImVec4(1, 0, 0, 1), "No world loaded. Enter folder name above.");
                }
            }
        }
        ImGui::End();
    }
}
