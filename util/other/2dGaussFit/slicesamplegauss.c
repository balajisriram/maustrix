/* C file autogenerated by mexme.m */
#include <mex.h>
#include <math.h>
#include <matrix.h>
#include <stdlib.h>
#include <float.h>
#include <string.h>

/* Translate matlab types to C */
#define uint64 unsigned long int
#define int64 long int
#define uint32 unsigned int
#define int32 int
#define uint16 unsigned short
#define int16 short
#define uint8 unsigned char
#define int8 char
#define single float

#include "mexmetypecheck.c"

/* Your extra includes and function definitions here */
#include "logpdf.c"
        
void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[] )
{

/*Input output boilerplate*/
    if(!((nlhs == 1 && nrhs == 11) || (nlhs == 0 && nrhs == 1)))
        mexErrMsgTxt("Function must be called with 11 arguments and has 1 return values");
    
    const mxArray *x_ptr = prhs[0];
    mexmetypecheck(x_ptr,mxDOUBLE_CLASS,"Argument x (#1) is expected to be of type double");
    const mwSize   x_m = mxGetM(x_ptr);
    const mwSize   x_n = mxGetN(x_ptr);
    const mwSize   x_length = x_m == 1 ? x_n : x_m;
    const mwSize   x_numel = mxGetNumberOfElements(x_ptr);
    const int      x_ndims = mxGetNumberOfDimensions(x_ptr);
    const mwSize  *x_size = mxGetDimensions(x_ptr);
    
    
    if(nrhs == 1)
    {
        /*Set the seed for the M twister*/
        unsigned int *y = (unsigned int *) mxGetData(x_ptr);
        init_by_array(y,x_numel);
        return;
    }
    
    const double  *xin = (double *) mxGetData(x_ptr);
    x = mxMalloc(sizeof(double)*x_numel);
    for(int i = 0; i < x_numel; i++)
        x[i] = xin[i];

    const mxArray *xi_ptr = prhs[1];
    mexmetypecheck(xi_ptr,mxDOUBLE_CLASS,"Argument xi (#2) is expected to be of type double");
    const mwSize   xi_m = mxGetM(xi_ptr);
    const mwSize   xi_n = mxGetN(xi_ptr);
                   xi_length = xi_m == 1 ? xi_n : xi_m;
    const mwSize   xi_numel = mxGetNumberOfElements(xi_ptr);
    const int      xi_ndims = mxGetNumberOfDimensions(xi_ptr);
    const mwSize  *xi_size = mxGetDimensions(xi_ptr);
                   xi = (double *) mxGetData(xi_ptr);
    const mxArray *yi_ptr = prhs[2];
    mexmetypecheck(yi_ptr,mxDOUBLE_CLASS,"Argument yi (#3) is expected to be of type double");
    const mwSize   yi_m = mxGetM(yi_ptr);
    const mwSize   yi_n = mxGetN(yi_ptr);
                   yi_length = yi_m == 1 ? yi_n : yi_m;
    const mwSize   yi_numel = mxGetNumberOfElements(yi_ptr);
    const int      yi_ndims = mxGetNumberOfDimensions(yi_ptr);
    const mwSize  *yi_size = mxGetDimensions(yi_ptr);
                   yi = (double *) mxGetData(yi_ptr);
    const mxArray *zi_ptr = prhs[3];
    mexmetypecheck(zi_ptr,mxDOUBLE_CLASS,"Argument zi (#4) is expected to be of type double");
    const mwSize   zi_m = mxGetM(zi_ptr);
    const mwSize   zi_n = mxGetN(zi_ptr);
    const mwSize   zi_length = zi_m == 1 ? zi_n : zi_m;
                   zi_numel = mxGetNumberOfElements(zi_ptr);
    const int      zi_ndims = mxGetNumberOfDimensions(zi_ptr);
    const mwSize  *zi_size = mxGetDimensions(zi_ptr);
                   zi = (double *) mxGetData(zi_ptr);
    const mxArray *a_ptr = prhs[4];
    mexmetypecheck(a_ptr,mxDOUBLE_CLASS,"Argument a (#5) is expected to be of type double");
    if(mxGetNumberOfElements(a_ptr) != 1)
        mexErrMsgTxt("Argument a (#5) must be scalar");
                   a = (double) mxGetScalar(a_ptr);
    const mxArray *b_ptr = prhs[5];
    mexmetypecheck(b_ptr,mxDOUBLE_CLASS,"Argument b (#6) is expected to be of type double");
    if(mxGetNumberOfElements(b_ptr) != 1)
        mexErrMsgTxt("Argument b (#6) must be scalar");
                   b = (double) mxGetScalar(b_ptr);
    const mxArray *rgx_ptr = prhs[6];
    mexmetypecheck(rgx_ptr,mxDOUBLE_CLASS,"Argument rgx (#7) is expected to be of type double");
    const mwSize   rgx_m = mxGetM(rgx_ptr);
    const mwSize   rgx_n = mxGetN(rgx_ptr);
    const mwSize   rgx_length = rgx_m == 1 ? rgx_n : rgx_m;
    const mwSize   rgx_numel = mxGetNumberOfElements(rgx_ptr);
    const int      rgx_ndims = mxGetNumberOfDimensions(rgx_ptr);
    const mwSize  *rgx_size = mxGetDimensions(rgx_ptr);
                   rgx = (double *) mxGetData(rgx_ptr);
    const mxArray *rgy_ptr = prhs[7];
    mexmetypecheck(rgy_ptr,mxDOUBLE_CLASS,"Argument rgy (#8) is expected to be of type double");
    const mwSize   rgy_m = mxGetM(rgy_ptr);
    const mwSize   rgy_n = mxGetN(rgy_ptr);
    const mwSize   rgy_length = rgy_m == 1 ? rgy_n : rgy_m;
    const mwSize   rgy_numel = mxGetNumberOfElements(rgy_ptr);
    const int      rgy_ndims = mxGetNumberOfDimensions(rgy_ptr);
    const mwSize  *rgy_size = mxGetDimensions(rgy_ptr);
                   rgy = (double *) mxGetData(rgy_ptr);
    const mxArray *sigma_ptr = prhs[8];
    mexmetypecheck(sigma_ptr,mxDOUBLE_CLASS,"Argument sigma (#9) is expected to be of type double");
    if(mxGetNumberOfElements(sigma_ptr) != 1)
        mexErrMsgTxt("Argument sigma (#9) must be scalar");
                   sigma = (double) mxGetScalar(sigma_ptr);
    const mxArray *sigmasize_ptr = prhs[9];
    mexmetypecheck(sigmasize_ptr,mxDOUBLE_CLASS,"Argument sigmasize (#10) is expected to be of type double");
    if(mxGetNumberOfElements(sigmasize_ptr) != 1)
        mexErrMsgTxt("Argument sigmasize (#10) must be scalar");
                   sigmasize = (double) mxGetScalar(sigmasize_ptr);
    const mxArray *nsamples_ptr = prhs[10];
    mexmetypecheck(nsamples_ptr,mxDOUBLE_CLASS,"Argument nsamples (#11) is expected to be of type double");
    if(mxGetNumberOfElements(nsamples_ptr) != 1)
        mexErrMsgTxt("Argument nsamples (#11) must be scalar");
                   nsamples = (double) mxGetScalar(nsamples_ptr);


    mwSize samples_dims[] = {x_numel,nsamples};
    plhs[0] = mxCreateNumericArray(2,samples_dims,mxDOUBLE_CLASS,mxREAL);
    mxArray **samples_ptr = &plhs[0];
    double   *samples = (double *) mxGetData(*samples_ptr);

    /*Actual function*/

    #include "slicesample.c"

}
