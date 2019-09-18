#include <windows.h>

int nScreenWidth = 120;
int nScreenHeight = 40;

int wmain() {
    wchar_t* screen = new wchar_t[nScreenWidth * nScreenHeight];
    HANDLE hConsole = CreateConsoleScreenBuffer(GENERIC_READ | GENERIC_WRITE, 0, NULL, CONSOLE_TEXTMODE_BUFFER, NULL);
    SetConsoleActiveScreenBuffer(hConsole);
    DWORD dwBytesWritten = 0;

    while (1) {
        for (int x = 0; x < nScreenWidth; x++) {
            for (int y = 0; y < nScreenHeight; y++) {
                screen[y * nScreenWidth + x] = 0;
            }
        }
        screen[39 * nScreenWidth + 119] = 'A';

        //screen[nScreenWidth * nScreenHeight - 1] = '\0';
        WriteConsoleOutputCharacter(hConsole, screen, nScreenWidth * nScreenHeight, { 0, 0 }, &dwBytesWritten);
    }

    return 0;
}