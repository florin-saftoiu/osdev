#include <iostream>
using namespace std;

int main() {
    cout << "hello_" << endl;
    int* i = (int*) malloc(sizeof(int));
    *i = 10;
    cout << *i << endl;
    free(i);

    return 0;
}