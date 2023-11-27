#include <chrono>
// #include <string>
// #include <cstring>

#ifdef __ANDROID__
#include <android/log.h>
#endif
#include <opencv2/opencv.hpp>
#include <opencv2/imgcodecs.hpp>
#include <vector>

#include <istream>
#include <string>
#include <stdint.h>

#include "NeuronPrototype.cpp"

using namespace cv;
using namespace std;
#if defined(__GNUC__)
    // Attributes to prevent 'unused' function from being removed and to make it visible
    #define FUNCTION_ATTRIBUTE __attribute__((visibility("default"))) __attribute__((used))
#elif defined(_MSC_VER)
    // Marking a function for export
    #define FUNCTION_ATTRIBUTE __declspec(dllexport)
#endif

#ifdef __cplusplus
#define EXTERNC extern "C"
#else
#define EXTERNC
#endif

long long int get_now() {
    return chrono::duration_cast<std::chrono::milliseconds>(
            chrono::system_clock::now().time_since_epoch()
    ).count();
}
#ifdef IS_WIN32
#include <windows.h>
#endif



// EXTERNC void platform_log(const char *fmt, ...) {
//     va_list args;
//     va_start(args, fmt);
// #ifdef __ANDROID__
//     __android_log_vprint(ANDROID_LOG_VERBOSE, "ndk", fmt, args);
// #elif defined(IS_WIN32)
//     char *buf = new char[4096];
//     std::fill_n(buf, 4096, '\0');
//     _vsprintf_p(buf, 4096, fmt, args);
//     OutputDebugStringA(buf);
//     delete[] buf;
// #else
//     vprintf(fmt, args);
// #endif
//     va_end(args);
// }


class cca_opencv_wrapper{

    private:

        Mat inp;
        Mat labels;
        Mat stats;
        Mat centroids;

    public:
        int max_idx = -1;
        int numObjects = 0;

        cca_opencv_wrapper( Mat input )
        {
            inp = input.clone();
            labels = Mat(input.size(), CV_16U);
            // labels = Mat(input.size(), CV_32S);

            if(inp.channels() == 3)
                cvtColor(inp, inp, cv::COLOR_BGR2GRAY);
            connectedComponentsWithStats(inp, labels, stats, centroids, 8, CV_16U);
            // connectedComponentsWithStats(inp, labels, stats, centroids, 8, CV_32S);

        }


        Mat getCentroids(){
            return centroids;
        }

        Mat getLabels(){
            return labels;
        }

        uint32_t get_most_left_of_centroid(int centroid_index)
        {
            return stats.at<int>(centroid_index, CC_STAT_LEFT);
        }
        
        uint32_t get_most_top_of_centroid(int centroid_index)
        {
            return stats.at<int>(centroid_index, CC_STAT_TOP);
        }
        
        uint32_t get_width_of_centroid(int centroid_index)
        {
            return stats.at<int>(centroid_index, CC_STAT_WIDTH);
        }
        
        uint32_t get_heigth_of_centroid(int centroid_index)
        {
            return stats.at<int>(centroid_index, CC_STAT_HEIGHT);
        }
        
        uint32_t get_area_of_component(int centroid_index)
        {
            // return 0;
            return stats.at<int>(centroid_index, CC_STAT_AREA);
        }
        
        uint16_t get_label_of_pixel(int x_pos, int y_pos)
        {
            return labels.at<int>(x_pos, y_pos);
        }

        uint8_t get_centroid_x(int index)
        {
            return centroids.at<int>(index, 0);
        }

        uint8_t get_centroid_y(int index)
        {
            return centroids.at<int>(index, 1);
        }

        size_t get_connected_component_count()
        {
            return centroids.rows;
        }

        uint32_t get_max_component_area()
        {
            uint32_t max_ = 0;
            for(auto i = 0; i < get_connected_component_count(); i++)
            {
                if(get_area_of_component(i) > max_ && i > 0){
                    max_ = get_area_of_component(i);
                    max_idx = i;
                }
            }
            return max_;
        }

        uint32_t get_min_component_area()
        {
            uint32_t min_ = inp.rows * inp.cols;
            for(auto i = 0; i < get_connected_component_count(); i++)
            {
                if(get_area_of_component(i) < min_)
                    min_ = get_area_of_component(i);
            }
            return min_;
        }

        float get_average_component_area()
        {
            uint32_t sum = 0;
            for(auto i = 0; i < get_connected_component_count(); i++)
            {
                sum = sum + get_area_of_component(i);
            }
            return ((float) sum) / (float) get_connected_component_count();
        }

        float get_standard_deviation_of_connected_compenent_areas()
        {
            float sum = 0;
            for(auto i = 0; i < get_connected_component_count(); i++)
            {
                sum = sum + ( abs( get_area_of_component(i) - get_average_component_area() ) );
            }
            return ((float) sum) / (float) get_connected_component_count();
        }

};



double sigmoid(double x, double c, double a) {
    return 1.0 / (1.0 + exp(-a * (x - c)));
}

EXTERNC bool isPrevEyesSaved = false;
Mat prev_left_eye_frame, prev_right_eye_frame;
Size net_input_size = Size(224,224);



void initializeCameraConstant(){
    vis_pref_vals = new double*[7];
    for (short camIdx = 0; camIdx < ncam; camIdx++){
        vis_pref_vals[camIdx] = new double[ncam];
    }
}



// Avoiding name mangling
// extern "C" {
    // Attributes to prevent 'unused' function from being removed and to make it visible
    // __attribute__((visibility("default"))) __attribute__((used))
    EXTERNC FUNCTION_ATTRIBUTE
    const char* version() {
        return CV_VERSION;
    }

    // __attribute__((visibility("default"))) __attribute__((used))
    // void process_image(char* inputImagePath, char* outputImagePath) {
    EXTERNC FUNCTION_ATTRIBUTE
    int findColorInImage(uint8_t* img, uint32_t imgLength, uint8_t* lowerB, uint8_t* upperB, uint8_t colorSpace, uint8_t* imgMask) {
        platform_log("INITIALIZE CAMERA CONSTANT Start : \n");
        initializeCameraConstant();
        platform_log("INITIALIZE CAMERA CONSTANT DONE : \n");
        // platform_log(std::to_string(epochs).c_str());

        vector<uint8_t> buffer(img, img + imgLength);
        Mat imageRgb = imdecode(buffer, IMREAD_COLOR);;

        Mat uframe, frame, grayFrame, xframe, leftFrame, rightFrame, bwframe;
        Mat leftGrayFrame, rightGrayFrame;
        leftFrame = imageRgb(Rect(0, 0, 240, 240));
        rightFrame = imageRgb(Rect(70, 0, 240, 240));
        if (!isPrevEyesSaved){
            resize(leftFrame, prev_left_eye_frame, net_input_size);            
            resize(rightFrame, prev_right_eye_frame, net_input_size);            
            isPrevEyesSaved = true;
        }
        // rightFrame = imageRgb(Range(80,1), Range(120-1,140-1));
        //cv::resize (InputArray src, OutputArray dst, Size dsize, double fx=0, double fy=0, int interpolation=INTER_LINEAR)
        double this_score = 0;
        double this_left_score = 0;
        double this_right_score = 0;
        double meanx = 0;

        for (int ncam = 0; ncam < 2; ncam++){
            if (ncam == 0){
                resize(leftFrame, uframe, net_input_size);
                cvtColor(uframe, grayFrame, COLOR_BGR2GRAY);
                cvtColor(prev_left_eye_frame, leftGrayFrame, COLOR_BGR2GRAY);
                subtract(grayFrame, leftGrayFrame, xframe);
            }else{
                resize(rightFrame, uframe, net_input_size);
                cvtColor(uframe, grayFrame, COLOR_BGR2GRAY);
                cvtColor(prev_right_eye_frame, rightGrayFrame, COLOR_BGR2GRAY);
                subtract(grayFrame, rightGrayFrame, xframe);
            }
            // left_uframe = uframe;
            //convertTo (OutputArray m, int rtype, double alpha=1, double beta=0) const
            uframe.convertTo(frame, CV_32FC3);
            // cvtColor(prev_left_eye_frame, prev_left_eye_frame, COLOR_BGR2GRAY)
            // subtract(, , xframe);
            for (int ncol = 0; ncol < 3; ncol++) {
                Mat colframe;
                if (ncol == 0) {
                    Mat channels[3];
                    split(uframe, channels);
                    Mat temp1 = channels[0];
                    Mat temp2 = channels[1] * 1.5;
                    Mat temp3 = channels[2] * 1.5;
                    //cv::compare (InputArray src1, InputArray src2, OutputArray dst, int cmpop)
                    compare(temp1, temp2, colframe, CMP_GT);
                    compare(temp1, temp3, temp1, CMP_GT);
                    //cv::bitwise_and (InputArray src1, InputArray src2, OutputArray dst, InputArray mask=noArray())
                    bitwise_and(colframe, temp1, colframe);
                    compare(temp1, 50, temp1, CMP_LT);
                    colframe.setTo(0, temp1);
                } else if (ncol == 1) {
                    // Mat temp1 = uframe.col(1);
                    // Mat temp2 = uframe.col(0) * 1.3;
                    // Mat temp3 = uframe.col(2) * 1.3;
                    Mat channels[3];
                    split(uframe, channels);
                    Mat temp1 = channels[1];
                    Mat temp2 = channels[0] * 1.3;
                    Mat temp3 = channels[2] * 1.3;

                    compare(temp1, temp2, colframe, CMP_GT);
                    compare(temp1, temp3, temp1, CMP_GT);
                    bitwise_and(colframe, temp1, colframe);
                    compare(temp1, 50, temp1, CMP_LT);
                    colframe.setTo(0, temp1);
                } else {
                    // Mat temp1 = uframe.col(2);
                    // Mat temp2 = uframe.col(1) * 1.2;
                    // Mat temp3 = uframe.col(0) * 1.2;
                    Mat channels[3];
                    split(uframe, channels);
                    Mat temp1 = channels[2];
                    Mat temp2 = channels[1] * 1.2;
                    Mat temp3 = channels[0] * 1.2;

                    compare(temp1, temp2, colframe, CMP_GT);
                    compare(temp1, temp3, temp1, CMP_GT);
                    bitwise_and(colframe, temp1, colframe);
                    compare(temp1, 50, temp1, CMP_LT);
                    colframe.setTo(0, temp1);
                }



                // Mat blob;
                //cv::connectedComponents (InputArray image, OutputArray labels, int connectivity, int ltype, int ccltype)
                // connectedComponents(colframe, blob);
                cca_opencv_wrapper cca_wrapper = cca_opencv_wrapper(colframe);
                // int x = cca_wrapper.get_most_left_of_centroid(cca_wrapper.max_idx);
                // int y = cca_wrapper.get_most_top_of_centroid(cca_wrapper.max_idx);
                // int w = cca_wrapper.get_heigth_of_centroid(cca_wrapper.max_idx);
                // int h = cca_wrapper.get_width_of_centroid(cca_wrapper.max_idx);

                // rectangle(colframe, Rect( Point( x,y ), Point(x + w, y + h) ),  Scalar(255, 255, 255), 3);
                if (cca_wrapper.get_connected_component_count() > 0) {
                    // i = max area
                    // j = max_idx
                    // npx = max_idx
                    // [i, j] = max(cellfun(@numel,blob.PixelIdxList));
                    // npx = i;
                    // [~, x] = ind2sub(blob.ImageSize, blob.PixelIdxList{j});
                    // this_score = sigmoid(npx, 1000, 0.0075) * 50;
                    // this_left_score = sigmoid(((228 - mean(x)) / 227), 0.85, 10) * this_score;
                    // this_right_score = sigmoid(((mean(x)) / 227), 0.85, 10) * this_score;                    
                    uint32_t max_size = 0;
                    int max_idx = 0;

                    max_size = cca_wrapper.get_max_component_area();
                    double meanx = cca_wrapper.get_centroid_x(cca_wrapper.max_idx);
                   
                    this_score = sigmoid(max_size, 1000, 0.0075) * 50;
                    this_left_score = sigmoid(((228 - meanx) / 227.0), 0.85, 10) * this_score;
                    this_right_score = sigmoid(((meanx) / 227.0), 0.85, 10) * this_score;
                } else {
                    meanx = 0;
                    this_score = 0;
                    this_left_score = 0;
                    this_right_score = 0;                    
                    // platform_log(std::to_string(777788889999).c_str());
                    // vis_pref_vals[ncol * 2] = 0;
                    // vis_pref_vals[ncol * 2 + 1] = 0;
                }
                // platform_log("STRRRR\n");
                // platform_log(std::to_string(ncol * 2 + 1).c_str());
                // platform_log("\n");
                // platform_log(std::to_string(ncam).c_str());
                // platform_log(std::to_string(this_left_score).c_str());
                // platform_log(std::to_string(this_right_score).c_str());
                vis_pref_vals[ncol * 2][ncam] = this_score;
                if (ncam == 0) {
                    vis_pref_vals[ncol * 2+1][ncam] = this_left_score;
                }
                else{                    
                    vis_pref_vals[ncol * 2+1][ncam] = this_right_score;
                }

            }
            

            Mat channels[3];
            split(uframe, channels);
            // compare(xframe, 20, xframe, CMP_GT);
            threshold(xframe, bwframe, 20, 255, THRESH_BINARY);            
            
            // bwframe.setTo(0, xframe);
            // platform_log("SIZE : \n");
            // platform_log(std::to_string(bwframe.size().width).c_str());
            // platform_log("\n");
            // platform_log(std::to_string(bwframe.size().height).c_str());
            // platform_log("\n");
            // platform_log(std::to_string(bwframe.channels()).c_str());
            // platform_log("\n");
            // platform_log("@^ channels \n");


            cca_opencv_wrapper cca_wrapper_bw = cca_opencv_wrapper(bwframe);
            // break;
            if (cca_wrapper_bw.get_connected_component_count() > 0) {
                uint32_t max_size = 0;
                int max_idx = 0;

                max_size = cca_wrapper_bw.get_max_component_area();
                double meanx = cca_wrapper_bw.get_centroid_x(cca_wrapper_bw.max_idx);
                
                this_score = sigmoid(max_size, 1000, 0.0075) * 50;


            }else{
                this_score = 0;
            }


            vis_pref_vals[6][ncam] = this_score;


            if (ncam == 0){
                prev_left_eye_frame = uframe;
            }else{
                prev_right_eye_frame = uframe;
            }

        }

        
        return 0;
    }

    FUNCTION_ATTRIBUTE
    int findColorInImageOld(uint8_t* img, uint32_t imgLength, uint8_t* lowerB, uint8_t* upperB, uint8_t colorSpace, uint8_t* imgMask) {
        vector<uint8_t> buffer(img, img + imgLength);
        Mat imageRgb = imdecode(buffer, IMREAD_COLOR);;

        Mat imageHsv, imageMask;
        cvtColor(imageRgb, imageHsv, COLOR_BGR2HSV);
        // inRange(imageHsv, lowerB, upperB, imgMask);
        platform_log("CPP - findColorInImage\n");

        inRange(imageHsv, Scalar(lowerB[0], lowerB[1], lowerB[2]), Scalar(upperB[0], upperB[1], upperB[2]), imageMask);
        
        platform_log(std::to_string(imageMask.rows).c_str());
        platform_log("\n");
        platform_log(std::to_string(imageMask.step).c_str());
        platform_log("\n");

        int sum=0;
        sum = countNonZero(imageMask);
        platform_log("SUM:\n");
        platform_log(std::to_string(sum).c_str());
        platform_log("\n");

        // unsigned char *input = (unsigned char*)(imageMask.data);
        // namedWindow("window_detection_name");
        // imshow("window_detection_name", imageMask);

        // uint8_t *output = (uint8_t*)(imageMask.data);
        // platform_log(std::to_string(sizeof(input)).c_str());
        // platform_log("\n");
        // uint32_t idx = 0;
        // for(int j = 0;j < imageMask.rows;j++){
        //     for(int i = 0;i < imageMask.cols;i++){
        //         unsigned char b = input[imageMask.step * j + i ] ;
        //         unsigned char g = input[imageMask.step * j + i + 1];
        //         unsigned char r = input[imageMask.step * j + i + 2];
        //         sum += (b+g+r);
        //         // imgMask[idx] = output[imageMask.step * j + i ] ;
        //         // imgMask[idx+1] = output[imageMask.step * j + i + 1] ;
        //         // imgMask[idx+2] = output[imageMask.step * j + i + 2] ;
        //         // idx+=3;
        //     }
        //     // if (sum > 0) return sum;
        // }        

        // vector<uchar> jpeg_data;
        // vector<int> params(2);
        // params[0] = IMWRITE_JPEG_QUALITY;
        // params[1] = 95; // Set the JPEG quality (0-100)
        // imencode(".jpg", imageMask, jpeg_data, params);
        // platform_log("Image Mask\n");
        // platform_log(std::to_string(jpeg_data.size()).c_str());
        // platform_log("\n");
        // char *chars = (char*)jpeg_data.data();
        // for (int i = 0; i < jpeg_data.size();i++){
        //     imgMask[i] = chars[i];
        // }
        // uint8_t *rawOutput = (uint8_t*)(imageRgb.data);
        // idx = 0;
        // for(int j = 0;j < imageRgb.rows;j++){
        //     for(int i = 0;i < imageRgb.cols;i++){
        //         imgMask[idx] = rawOutput[imageRgb.step * j + i ] ;
        //         imgMask[idx+1] = rawOutput[imageRgb.step * j + i + 1] ;
        //         imgMask[idx+2] = rawOutput[imageRgb.step * j + i + 2] ;
        //         idx+=3;
        //     }
        //     // if (sum > 0) return sum;
        // }        

        // for(int i = 0; i < imageMask.rows; i++)
        // {
        //     // std::string s = "";
        //     const double* Mi = imageMask.ptr<double>(i);
        //     for(int j = 0; j < imageMask.cols; j++){
        //         // sum += std::max(Mi[j], 0.);                
        //         // s=s + Mi[j] + " _ ";
        //         // if (Mi[j]==255){
        //         //     platform_log("Mask Detected White");
        //         //     return 1;
        //         // }
        //         // platform_log(std::to_string(Mi[j]).c_str());
        //     }
        //     // platform_log("asdasd");
        //     // sum += std::max(Mi[j], 0.);
        // }        
        // for (uint32_t i = 0;i<imgLength;i++){
        //     if (imgMask[i]==255){
        //         return 1;
        //     }
        // }
        return sum;

        // long long start = get_now();        
        // Mat input = imread(inputImagePath, IMREAD_GRAYSCALE);
        // Mat threshed, withContours;

        // vector<vector<Point>> contours;
        // vector<Vec4i> hierarchy;
        
        // adaptiveThreshold(input, threshed, 255, ADAPTIVE_THRESH_GAUSSIAN_C, THRESH_BINARY_INV, 77, 6);
        // findContours(threshed, contours, hierarchy, RETR_TREE, CHAIN_APPROX_TC89_L1);
        
        // cvtColor(threshed, withContours, COLOR_GRAY2BGR);
        // drawContours(withContours, contours, -1, Scalar(0, 255, 0), 4);
        
        // imwrite(outputImagePath, withContours);
    }

    // int evalInMillis = static_cast<int>(get_now() - start);
    // platform_log("Processing done in %dms\n", evalInMillis);    
// }





// This is a piece of MATLAB code that is used to find the largest connected component (blob) in an image and its centroid.
// Here’s a breakdown of what each line does:
// [i, j] = max(cellfun(@numel,blob.PixelIdxList));: This line finds the index of the largest connected component in the image. cellfun(@numel,blob.PixelIdxList) applies the numel function to each cell in blob.PixelIdxList (which contains the linear indices of each connected component in the image), returning an array of the sizes of each connected component. max then returns the size of the largest component (i) and its index (j).
// npx = i;: This line simply stores the size of the largest connected component in npx.
// [~, x] = ind2sub(blob.ImageSize, blob.PixelIdxList{j});: This line converts the linear indices of the largest connected component into subscripts relative to the size of the original image (blob.ImageSize). The ~ is used to ignore the row indices, while x stores the column indices, effectively giving the x-coordinates of the pixels in the largest connected component.
// So, in summary, this code is used to find the largest connected component in an image and its x-coordinates. It’s often used in image processing tasks such as object detection or segmentation. Please note that this explanation assumes some familiarity with MATLAB and image processing concepts. If you’re not familiar with these, you might need to look up some terms for a deeper understanding.

