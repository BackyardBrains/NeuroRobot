// Online C++ compiler to run C++ program online
#include <iostream>
#include <thread>
#include <chrono>


short initial = 1;

void task1()
{
    initial = 3;
    while (initial % 2 == 1 ){
        // t1::sleep_for(std::chrono::milliseconds(250));
        std::this_thread::sleep_for(std::chrono::milliseconds(250));

    }
}

void task2()
{
    while (initial % 2 == 1){
        std::cout << "Hello world!"<< static_cast<short>(initial);
        // std::this_thread::sleep_for(std::chrono::milliseconds(50));
        // t2::sleep_for(std::chrono::milliseconds(250));
        std::this_thread::sleep_for(std::chrono::milliseconds(250));
        
    }
}
int main() {
    std::thread t1(task1);
    std::thread t2(task2);

    // // Wait for t1 to finish
    t1.detach();
    std::this_thread::sleep_for(std::chrono::milliseconds(2500));
    t2.detach();
    // if (thresholdProcessor[0].thresholdHit == true){
    //     thresholdProcessor[0].thresholdHit = false;
    //     return 1;
    // }    
    // Write C++ code here
    // int someInt = 5;
    // std::thread t([&]() {
    //     while (true)
    //     {
    //         if (someInt == 5){
    //             someInt = 7;

    //         }
    //     std::this_thread::sleep_for(std::chrono::milliseconds(250));
    //     }
    // });

    // t.detach();

    // std::thread t2([&]() {
    //     while (true)
    //     {
    //     std::this_thread::sleep_for(std::chrono::milliseconds(250));
    //         std::cout << "Hello world!"<< static_cast<int16_t>(someInt);
            
    //         // someInt *= 2;

    //     }
    // });
    std::cout << "Hello world!";
    // return 0;
}