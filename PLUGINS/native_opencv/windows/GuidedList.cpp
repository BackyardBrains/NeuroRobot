#include <iostream>
#include <thread>

struct Node {
  double data;
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

  void prepend(double data) {
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

  double pop_back() {
    if (head == nullptr) {
      // Handle empty list case
      return -1;
    }

    Node* node_to_delete = tail;
    double data = node_to_delete->data;

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
  // RHYTMIC NEURON
  std::thread rhytmicThread;
  bool isRhytmicBursting = false;
  double currentV = 0.0;
  double currentU = 0.0;
  // END OF RHYTMIC NEURON

  std::thread decayThread;

  double decayFactor = 1;
  double decayConstant = 0.155;
  short decayStep = 0;
  short decayTime = 0;
  bool isDecaying = false;


  void doWork() {
    // std::this_thread::sleep_for(std::chrono::milliseconds(delayTime));
    // std::this_thread::sleep_for(std::chrono::milliseconds(delayTime / 2));
    // std::this_thread::sleep_for(std::chrono::milliseconds(5000));
    auto start = std::chrono::high_resolution_clock::now();
    auto elapsed = std::chrono::high_resolution_clock::now() - start;
    long long microseconds = 0;

    long long remainingTime = delayTime;

    while (microseconds/1000 < delayTime && !isInterrupted){
      // if ( (remainingTime - (microseconds / 1000)) / 4 < 0) break;
      std::this_thread::sleep_for(std::chrono::milliseconds( (remainingTime - (microseconds / 1000)) / 4 ));
      elapsed = std::chrono::high_resolution_clock::now() - start;
      microseconds = std::chrono::duration_cast<std::chrono::microseconds>(elapsed).count();
      remainingTime = remainingTime - microseconds / 1000;
      if (microseconds < 30) break;
    }


    if (isInterrupted){
      isInterrupted = false;
      mode = 0;
      isWaiting = 0;
    }else{
      mode = 2;
      isWaiting = 3;
    }
  }

  void calculateExponentialDecay(short step) {
    decayMultipliers = decayFactor * exp(-decayConstant * step);
  }

  void startDecaying(){
    while (decayStep < 30 && !isDecayInterrupted && isInhibited){
      std::this_thread::sleep_for(std::chrono::milliseconds(30));
      calculateExponentialDecay(decayStep + 1);
      if (decayMultipliers < 0.01){
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
 // CHANGE TO PRIVATE
  DoublyLinkedList list;
  DoublyLinkedList valueList;

  GuidedList() {
    // list = nullptr;
    // startDelayThread();
  }

  DoublyLinkedList getList(){
    return list;
  }
  // GuidedList(DoublyLinkedList* list, short neuronType, bool isInhibitor) : list(list), neuronType(neuronType), isInhibitor(isInhibitor) {}
  // void setParameters(int idx, DoublyLinkedList* plist, short pneuronType, bool pisInhibited, short pdelayTime, DoublyLinkedList* pdelayValueLinkedList) {
  void setParameters(int idx, short pneuronType, bool pisInhibited, short pdelayTime) {
    neuronIdx = idx;
    // list = plist[idx];
    // valueList = pdelayValueLinkedList[idx];
    list = DoublyLinkedList();
    valueList = DoublyLinkedList();
    
    neuronType = pneuronType;
    isInhibited = pisInhibited;
    delayTime = pdelayTime;
  }
  int neuronIdx;
  short neuronType = -1000;
  bool isInhibited;
  short isSpiking = 0;
  short isWaiting = 0;
  // 0 - initial
  // 1 - will get a spiking signal call thread
  // 2 - thread called, flag to prevent calling another thread
  // 3 - thread delay finished
  long long prevTime;
  int listSize = 0;
  int valueListSize = 0;
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

  void clearAll(){
    list.clear();
    valueList.clear();
  }
  ~GuidedList() {
    // list.clear();
    // valueList.clear();
    // if (list != undefined){
    //   delete list;
    // }
    // if (list != nullptr) {
      // delete list; // Delete the list if we own it
    // }
  }

  double getFront(){
    return list.head->data;
  }

  // Add element to the front of the list
  void push_front(double data) {
    list.prepend(data);
    listSize++;
  }
  void push_value_front(double data) {
    valueList.prepend(data);
    valueListSize++;
  }

  // Remove element from the back of the list and return its data
  double pop_back() {
    listSize--;
    return list.pop_back();
  }
  double pop_value_back() {
    valueListSize--;
    return valueList.pop_back();
  }

  // Check if the list is empty
  bool empty() const {
    return list.head == nullptr;
  }

  double pushFrontPopBack(double data){
    list.prepend(data);
    return list.pop_back();
  }

  void processDecaying(){
    if (!isDecayInterrupted){
      // decayStep = 0; // reset decay
      applyDecaying(); // apply decay if it is not decaying yet
      
    }

  }

  void processInhibition(bool isInhibition){
    if (isInhibition) {
      // turn off decay thread
      isInterrupted = true;
      
      // isDecayInterrupted = true;
      if (!isDecayInterrupted){
        decayStep = 0;// question
      }
      
      // change mode to 0
      mode = 0;
      isWaiting = 0;
      // clear
      list.clear();
      valueList.clear();
      // decay inhibition
      applyDecaying();
      // isInhibited = false;
    }
  }


  // RYHTMIC NEURON
  void doRhytmicBursting(){
    while(true){
      // triggered by spike
      currentV = 1.0;
      std::this_thread::sleep_for(std::chrono::milliseconds(delayTime / 2));
      currentV = 0.0;

      if (isInterrupted){
        isInterrupted = false;
        mode = 0;
        isWaiting = 0;
      }else{
        mode = 2;
        isWaiting = 3;
      }
    }
  }
  void startRhytmicBursting(){
    rhytmicThread = std::thread(&GuidedList::doRhytmicBursting, this); // Pass 'this' for member function access
    rhytmicThread.detach();
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

// class GuidedRhytmicList: public GuidedList {
//   private:
//     std::thread rhytmicThread;
//   public:
//     bool isRhytmicBursting = false;
//     double currentV = 0.0;
//     double currentU = 0.0;

//   void setParameters(int idx, short pneuronType, bool pisInhibited, short pdelayTime) {
//     neuronIdx = idx;
//     neuronType = pneuronType;
//     isInhibited = pisInhibited;
//     delayTime = pdelayTime;
//   }


//     void doRhytmicBursting(){
//       while(true){
//         std::this_thread::sleep_for(std::chrono::milliseconds(delayTime / 2));
//         if (isInterrupted){
//           isInterrupted = false;
//           mode = 0;
//           isWaiting = 0;
//         }else{
//           mode = 2;
//           isWaiting = 3;
//         }
//       }
//     }
//     void startRhytmicBursting(){
//       rhytmicThread = std::thread(&GuidedRhytmicList::doRhytmicBursting, this); // Pass 'this' for member function access
//       rhytmicThread.detach();
//     }
// };

GuidedList* guidedDelayList;

// DoublyLinkedList* delayLinkedList;
// DoublyLinkedList* delayValueLinkedList;

// GuidedRhytmicList* guidedRhytmicList;
// DoublyLinkedList* rhytmicLinkedList;
