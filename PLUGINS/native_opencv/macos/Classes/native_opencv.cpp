#include <chrono>
// #include <string>
// #include <cstring>

#ifdef __ANDROID__
#include <android/log.h>
#endif
#include <opencv2/opencv.hpp>
#include <opencv2/imgcodecs.hpp>
#include <vector>

using namespace cv;
using namespace std;
#if defined(__GNUC__)
    // Attributes to prevent 'unused' function from being removed and to make it visible
    #define FUNCTION_ATTRIBUTE __attribute__((visibility("default"))) __attribute__((used))
#elif defined(_MSC_VER)
    // Marking a function for export
    #define FUNCTION_ATTRIBUTE __declspec(dllexport)
#endif


long long int get_now() {
    return chrono::duration_cast<std::chrono::milliseconds>(
            chrono::system_clock::now().time_since_epoch()
    ).count();
}
#ifdef IS_WIN32
#include <windows.h>
#endif

void platform_log(const char *fmt, ...) {
    va_list args;
    va_start(args, fmt);
#ifdef __ANDROID__
    __android_log_vprint(ANDROID_LOG_VERBOSE, "ndk", fmt, args);
#elif defined(IS_WIN32)
    char *buf = new char[4096];
    std::fill_n(buf, 4096, '\0');
    _vsprintf_p(buf, 4096, fmt, args);
    OutputDebugStringA(buf);
    delete[] buf;
#else
    vprintf(fmt, args);
#endif
    va_end(args);
}


double sigmoid(double x, double c, double a) {
    return 1.0 / (1.0 + exp(-a * (x - c)));
}

Mat prev_left_eye_frame, prev_right_eye_frame;
// Avoiding name mangling
extern "C" {
    // Attributes to prevent 'unused' function from being removed and to make it visible
    // __attribute__((visibility("default"))) __attribute__((used))
    FUNCTION_ATTRIBUTE
    const char* version() {
        return CV_VERSION;
    }

    // __attribute__((visibility("default"))) __attribute__((used))
    // void process_image(char* inputImagePath, char* outputImagePath) {
    FUNCTION_ATTRIBUTE
    int findColorInImage(uint8_t* img, uint32_t imgLength, uint8_t* lowerB, uint8_t* upperB, uint8_t colorSpace, uint8_t* imgMask) {
        vector<uint8_t> buffer(img, img + imgLength);
        Mat imageRgb = imdecode(buffer, IMREAD_COLOR);;


        Mat uframe, frame, xframe;
        //cv::resize (InputArray src, OutputArray dst, Size dsize, double fx=0, double fy=0, int interpolation=INTER_LINEAR)
        resize(imageRgb, uframe, Size(224,224));
        // left_uframe = uframe;
        //convertTo (OutputArray m, int rtype, double alpha=1, double beta=0) const
        uframe.convertTo(frame, CV_32FC3);
        cvtColor(uframe, uframe, COLOR_BGR2GRAY);
        // cvtColor(prev_left_eye_frame, prev_left_eye_frame, COLOR_BGR2GRAY)
        // subtract(, , xframe);
        for (int ncol = 0; ncol < 3; ncol++) {
            Mat colframe;
            if (ncol == 0) {
                // cv::Mat img = cv::imread("image.jpg");
                // std::vector<cv::Mat> channels;
                // cv::split(img, channels);
                // cv::Mat blueChannel = channels[0];
                // cv::Mat greenChannel = channels[1];
                // cv::Mat redChannel = channels[2];
                Mat channels[3];
                split(uframe, channels);
                Mat temp1 = uframe.col(0);
                Mat temp2 = uframe.col(1) * 1.5;
                Mat temp3 = uframe.col(2) * 1.5;
                //cv::compare (InputArray src1, InputArray src2, OutputArray dst, int cmpop)
                compare(temp1, temp2, colframe, CMP_GT);
                compare(temp1, temp3, temp1, CMP_GT);
                //cv::bitwise_and (InputArray src1, InputArray src2, OutputArray dst, InputArray mask=noArray())
                bitwise_and(colframe, temp1, colframe);
                compare(temp1, 50, temp1, CMP_LT);
                colframe.setTo(0, temp1);
            } else if (ncol == 1) {
                Mat temp1 = uframe.col(1);
                Mat temp2 = uframe.col(0) * 1.3;
                Mat temp3 = uframe.col(2) * 1.3;
                compare(temp1, temp2, colframe, CMP_GT);
                compare(temp1, temp3, temp1, CMP_GT);
                bitwise_and(colframe, temp1, colframe);
                compare(temp1, 50, temp1, CMP_LT);
                colframe.setTo(0, temp1);
            } else {
                Mat temp1 = uframe.col(2);
                Mat temp2 = uframe.col(1) * 1.2;
                Mat temp3 = uframe.col(0) * 1.2;
                compare(temp1, temp2, colframe, CMP_GT);
                compare(temp1, temp3, temp1, CMP_GT);
                bitwise_and(colframe, temp1, colframe);
                compare(temp1, 50, temp1, CMP_LT);
                colframe.setTo(0, temp1);
            }

            Mat blob;
            //cv::connectedComponents (InputArray image, OutputArray labels, int connectivity, int ltype, int ccltype)
            connectedComponents(colframe, blob);
            if (countNonZero(blob)) {
                int max_size = 0;
                int max_idx = 0;
                
                //!!!
                //https://stackoverflow.com/questions/37147762/python-connected-components-with-pixel-list
                for (int i = 1; i < blob.rows; i++) {
                    for (int j = 1; j < blob.cols; j++) {
                        if (blob.at<int>(i, j) == 1) {
                            Mat temp;

                            // int cv::floodFill (InputOutputArray image, InputOutputArray mask, Point seedPoint, Scalar newVal, Rect *rect=0, Scalar loDiff=Scalar(), Scalar upDiff=Scalar(), int flags=4)
                            floodFill(blob, temp, Point(j, i), 2);
                            int size = countNonZero(temp == 2);
                            if (size > max_size) {
                                max_size = size;
                                max_idx = j;
                            }
                        }
                    }
                }
                
                // !!!
                double this_score = sigmoid(max_size, 1000, 0.0075) * 50;
                double this_left_score = sigmoid(((228 - max_idx) / 227.0), 0.85, 10) * this_score;
                double this_right_score = sigmoid(((max_idx) / 227.0), 0.85, 10) * this_score;
                // vis_pref_vals[ncol * 2] = (ncam == 1) ? this_left_score : this_right_score;
                // vis_pref_vals[ncol * 2 + 1] = this_score;
            } else {
                // vis_pref_vals[ncol * 2] = 0;
                // vis_pref_vals[ncol * 2 + 1] = 0;
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
}