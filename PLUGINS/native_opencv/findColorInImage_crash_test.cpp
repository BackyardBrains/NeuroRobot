#include <opencv2/opencv.hpp>
#include <iostream>
#include <vector>

using namespace cv;
using namespace std;

// Mock global pointers
double *vis_pref_vals = new double[100];
short *visPrefs = new short[100];
int vis_prefs_count = 22;

void setPreprocessMatrixValue(double *arr, short pi, short pj, short per_row, double value){
    if (arr == nullptr) return;
    int index = pj * per_row + pi;
    if (index >= 0 && index < 44) {
        arr[index] =  value;
    } else {
        cout << "Index out of bounds: " << index << endl;
    }
}

class cca_opencv_wrapper{
    private:
        Mat inp;
        Mat labels;
        Mat stats;
        Mat centroids;
    public:
        int max_idx = -1;
        int numObjects = 0;

        void clearAll(){
            inp.release(); labels.release(); stats.release(); centroids.release();
        }

        cca_opencv_wrapper( Mat input ){
            inp = input.clone();
            labels = Mat(input.size(), CV_16U);
            if(inp.channels() == 3) cvtColor(inp, inp, cv::COLOR_BGR2GRAY);
            connectedComponentsWithStats(inp, labels, stats, centroids, 8, CV_16U);
        }

        uint32_t get_max_component_area(){
             if (centroids.rows <= 1) return 0; // Background only
             int maxArea = 0;
             for(int i=1; i<centroids.rows; i++){
                 int area = stats.at<int>(i, CC_STAT_AREA);
                 if(area > maxArea){
                     maxArea = area;
                     max_idx = i;
                 }
             }
             return maxArea;
        }
        
        double get_centroid_x(int index) { return centroids.at<double>(index, 0); }
        int get_most_left_of_centroid(int idx) { return stats.at<int>(idx, CC_STAT_LEFT); }
        int get_most_top_of_centroid(int idx) { return stats.at<int>(idx, CC_STAT_TOP); }
        size_t get_connected_component_count() { return centroids.rows; }
};

double sigmoid(double xx, double cc, double aa) {
    return 1.0 / (1.0 + exp(-aa * (xx - cc)));
}

int main() {
    // 1. Create a dummy Green image (BGR)
    Mat imageRgb(240, 320, CV_8UC3, Scalar(0, 0, 0));
    rectangle(imageRgb, Point(100, 100), Point(150, 150), Scalar(0, 255, 0), -1); // Green square

    // 2. Mock processing variables
    Mat uframe = imageRgb;
    int ncol = 1; // Green
    int icam = 0; 
    uint16_t centroid[9] = {0};

    // 3. Logic extraction from native_opencv.cpp (Green path)
    cout << "Starting Green Detection Logic..." << endl;
    
    Mat colframe;
    vector<Mat> channels;
    split(uframe, channels); 

    Mat ch_main = channels[1]; // Green channel
    Mat ch_other1_scaled, ch_other2_scaled;
    
    // Check for crash here
    cout << "Scaling channels..." << endl;
    convertScaleAbs(channels[2], ch_other1_scaled, 1.3, 0); // Red * 1.3
    convertScaleAbs(channels[0], ch_other2_scaled, 1.3, 0); // Blue * 1.3

    Mat mask1, mask2, maskBrightness;
    cout << "Comparing..." << endl;
    compare(ch_main, ch_other1_scaled, mask1, CMP_GT);
    compare(ch_main, ch_other2_scaled, mask2, CMP_GT);
    bitwise_and(mask1, mask2, colframe);

    compare(ch_main, 50, maskBrightness, CMP_GT);
    bitwise_and(colframe, maskBrightness, colframe);
    
    cout << "CCA..." << endl;
    cca_opencv_wrapper cca_wrapper = cca_opencv_wrapper(colframe);
    if (cca_wrapper.get_connected_component_count() > 1) {
        cout << "Object detected!" << endl;
        uint32_t max_size = cca_wrapper.get_max_component_area();
        double this_score = sigmoid(max_size, 1000, 0.0075) * 70;
        
        cout << "Score: " << this_score << endl;
        
        short tempCol = static_cast<short>(ncol * 2);
        setPreprocessMatrixValue(vis_pref_vals, tempCol, icam, vis_prefs_count, this_score);
    } else {
        cout << "No object detected." << endl;
    }

    cout << "Finished successfully." << endl;
    return 0;
}
