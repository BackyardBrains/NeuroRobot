#include <iostream>
#include <thread>

struct Node {
  short data;
  Node* prev;
  Node* next;
};

class DoublyLinkedList {
 private:

 public:
  Node* head;
  Node* tail;
  DoublyLinkedList() {
    head = nullptr;
    tail = nullptr;
  }

  ~DoublyLinkedList() {
    // Destructor to clear the list and deallocate memory
    while (head != nullptr) {
      pop_back();
    }
  }

  void clear(){
    while (head != nullptr) {
      pop_back();
    }
  }

  void prepend(short data) {
    Node* new_node = new Node;
    new_node->data = data;
    new_node->prev = nullptr;

    if (head == nullptr) {
      new_node->next = nullptr;
      head = tail = new_node;
    } else {
      new_node->next = head;
      head->prev = new_node;
      head = new_node;
    }
  }

  short pop_back() {
    if (head == nullptr) {
      // Handle empty list case
      return -1;
    }

    Node* node_to_delete = tail;
    short data = node_to_delete->data;

    if (head == tail) {
      head = tail = nullptr;
    } else {
      tail = tail->prev;
      tail->next = nullptr;
    }

    delete node_to_delete;
    return data;
  }
};
/* GuidedList
/// @brief Guided list is a 
/// @params

if (this neuron receive any active inhibition ){
 // check in connectome
}else
if (this neuron active using current neuron type : burst when activated) {
  // change mode to 1, activate thread
    // when thread finished, change mode directly to 2 - to start pop and receive data without using thread 
}
*/
class GuidedList {
 private:
  DoublyLinkedList list;

  std::thread decayThread;

  double decayConstant = 0.1;
  short decayStep = 0;
  short decayTime = 0;
  bool isDecaying = false;


  void doWork() {
    std::this_thread::sleep_for(std::chrono::milliseconds(delayTime));
    // std::this_thread::sleep_for(std::chrono::milliseconds(5000));
    if (isInterrupted){
      isInterrupted = false;
      mode = 0;
    }else{
      mode = 2;
    }
  }

  void calculateExponentialDecay(short step) {
    decayMultipliers = exp(-decayConstant * step);
  }

  void startDecaying(){
    while (decayStep < 10){
      std::this_thread::sleep_for(std::chrono::milliseconds(100));
      calculateExponentialDecay(decayStep + 1);
      if (decayMultipliers < 0.1){
        isInhibited = false;
        isDecaying = false;
        decayStep = 0;
      }
      decayStep++;
    }
    isDecaying = false;
    decayStep=0;
  }

  void applyDecaying(){
    if (isDecaying == false){
      isDecaying = true;

      decayThread = std::thread(&GuidedList::startDecaying, this); // Pass 'this' for member function access
      decayThread.detach();

    }

    // interrupt decay,
    // create new decay

  }

 public:
  GuidedList() {
    // list = nullptr;
    // startDelayThread();
  }
  // GuidedList(DoublyLinkedList* list, short neuronType, bool isInhibitor) : list(list), neuronType(neuronType), isInhibitor(isInhibitor) {}
  void setParameters(int idx, DoublyLinkedList* plist, short pneuronType, bool pisInhibited, short pdelayTime) {
    neuronIdx = idx;
    list = plist[idx];
    neuronType = pneuronType;
    isInhibited = pisInhibited;
    delayTime = pdelayTime;
  }
  int neuronIdx;
  short neuronType = -1000;
  bool isInhibited;
  long long prevTime;
  int listSize = 0;
  bool isInterrupted = false;
  bool isDecayInterrupted = false;
  short delayTime = 1000;
  short mode = 0;
  // 0 - has not received spike because is not Spiking
  // 1 - received Spike - accumulating
  // 2 - turn off time - fully FIFO

  double decayMultipliers = 0.0;
  std::thread delayThread;

  void startDelayThread() {
    // myThread = std::thread(&MyClass::doWork, this);
    delayThread = std::thread(&GuidedList::doWork, this); // Pass 'this' for member function access
    delayThread.detach();
    
    // Alternatively, consider std::thread::detach() for automatic thread cleanup
  }
  // Destructor to avoid memory leaks (assuming caller doesn't manage the list)
  ~GuidedList() {
    // list.clear();
    // if (list != undefined){
    //   delete list;
    // }
    // if (list != nullptr) {
      // delete list; // Delete the list if we own it
    // }
  }

  short getFront(){
    return list.head->data;
  }

  // Add element to the front of the list
  void push_front(short data) {
    list.prepend(data);
    listSize++;
  }

  // Remove element from the back of the list and return its data
  short pop_back() {
    listSize--;
    return list.pop_back();
  }

  // Check if the list is empty
  bool empty() const {
    return list.head == nullptr;
  }

  short pushFrontPopBack(short data){
    list.prepend(data);
    return list.pop_back();
  }



  void processInhibition(bool isInhibited){
    if (isInhibited) {
      // turn off thread
      isInterrupted = true;
      
      // isDecayInterrupted = true;
      decayStep = 0;
      
      // change mode to 0
      // mode = 0;
      // clear
      list.clear();
      // decay inhibition
      applyDecaying();
      // isInhibited = false;
    }
  }



  // Node* toArray(int& size) const {

  //   if (size == 0) {
  //     return nullptr; // No elements, return nullptr
  //   }
  //   if (size>listSize){
  //     size=listSize;
  //   }

  //   Node* array = new Node[size];

  //   // size = 0;  // Reset size for indexing
  //   for (int i = 0; i <size; i++){
  //     // Traverse the current_list and copy data to array[size]
  //     array[i] = &list[i].head;
  //   }

  //   return array;
  // }
};

GuidedList* guidedDelayList;
DoublyLinkedList* delayLinkedList;
