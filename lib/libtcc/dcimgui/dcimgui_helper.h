#include <d3d9.h>
#include <Windows.h>
#include <dcimgui.h>
#include <dcimgui_impl_dx9.h>
#include <dcimgui_impl_win32.h>
#include <MinHook.h>
#include <string.h>

extern LRESULT cImGui_ImplWin32_WndProcHandler(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam);

struct {
    HRESULT(WINAPI *present)(IDirect3DDevice9*, const RECT*, const RECT*, HWND, const RGNDATA*);
    HRESULT(WINAPI *end_scene)(IDirect3DDevice9*);
    HRESULT(WINAPI *reset)(IDirect3DDevice9*, D3DPRESENT_PARAMETERS*);
    void *wnd_proc_addr;
    WNDPROC wnd_proc;
} g_helper_imgui_hooks;

static uintptr_t find_d3d9_base(void) {
    static uintptr_t base = 0;
    
    if (base == 0) {
        char path[MAX_PATH] = {0};
        DWORD size = GetSystemDirectoryA(path, MAX_PATH);
        
        if (size > 0) {
            strcat(path, "\\d3d9.dll");
            uintptr_t obj_base = (uintptr_t)LoadLibraryA(path);
            
            while (obj_base++ < obj_base + 0x128000) {
                if (*(uint16_t*)(obj_base + 0x00) == 0x06C7 &&
                    *(uint16_t*)(obj_base + 0x06) == 0x8689 &&
                    *(uint16_t*)(obj_base + 0x0C) == 0x8689) {
                    obj_base += 2;
                    base = obj_base;
                    break;
                }
            }
        }
    }
    
    return base;
}

void Helper_ImGui_Install_Present_Hook(void *present, void *reset) {
    uintptr_t base = find_d3d9_base();
    void **d3d9_vtbl = *(void***)(void*)base;
    
    MH_CreateHook(d3d9_vtbl[17], present, (void**)&g_helper_imgui_hooks.present);
    MH_EnableHook(d3d9_vtbl[17]);
    MH_CreateHook(d3d9_vtbl[16], reset, (void**)&g_helper_imgui_hooks.reset);
    MH_EnableHook(d3d9_vtbl[16]);
}

void Helper_ImGui_Install_EndScene_Hook(void *end_scene, void *reset) {
    uintptr_t base = find_d3d9_base();
    void **d3d9_vtbl = *(void***)(void*)base;
    
    MH_CreateHook(d3d9_vtbl[42], end_scene, (void**)&g_helper_imgui_hooks.end_scene);
    MH_EnableHook(d3d9_vtbl[42]);
    MH_CreateHook(d3d9_vtbl[16], reset, (void**)&g_helper_imgui_hooks.reset);
    MH_EnableHook(d3d9_vtbl[16]);
}

void Helper_ImGui_Init(IDirect3DDevice9 *device, void *wnd_proc) {
    D3DDEVICE_CREATION_PARAMETERS params;
    IDirect3DDevice9_GetCreationParameters(device, &params);
    
    CIMGUI_CHECKVERSION();
    ImGui_CreateContext(NULL);
    cImGui_ImplWin32_Init(params.hFocusWindow);
    cImGui_ImplDX9_Init(device);
    
    g_helper_imgui_hooks.wnd_proc_addr = (void*)GetWindowLongPtrA(params.hFocusWindow, GWLP_WNDPROC);
    MH_CreateHook(g_helper_imgui_hooks.wnd_proc_addr, wnd_proc, (void**)&g_helper_imgui_hooks.wnd_proc);
    MH_EnableHook(g_helper_imgui_hooks.wnd_proc_addr);
}

void Helper_ImGui_Destroy(void) {
    if (g_helper_imgui_hooks.end_scene)
        MH_DisableHook((void*)g_helper_imgui_hooks.end_scene);
    if (g_helper_imgui_hooks.present)
        MH_DisableHook((void*)g_helper_imgui_hooks.present);
    
    MH_DisableHook(g_helper_imgui_hooks.reset);
    MH_DisableHook(g_helper_imgui_hooks.wnd_proc_addr);
    
    cImGui_ImplDX9_Shutdown();
    cImGui_ImplWin32_Shutdown();
    ImGui_DestroyContext(NULL);
}

#define HELPER_IMGUI_WND_PROC(hWnd, uMsg, wParam, lParam) \
    g_helper_imgui_hooks.wnd_proc(hWnd, uMsg, wParam, lParam)

#define HELPER_IMGUI_PRESENT(device, src_rect, dest_rect, dest_window, dirty_region) \
    g_helper_imgui_hooks.present(device, src_rect, dest_rect, dest_window, dirty_region)

#define HELPER_IMGUI_END_SCENE(device) \
    g_helper_imgui_hooks.end_scene(device)

#define HELPER_IMGUI_RESET(device, present_params) \
    g_helper_imgui_hooks.reset(device, present_params)
