#include "evaluate.h"

void recall_and_ratio(float ** &dataset, float ** &querypoints, int data_dimensionality, int ** &queryknn_results, long int ** &gt, int query_size) {
    // int ks[6] = {1, 10, 20, 30, 40, 50};
    
    // int ks[2] = {1,10};
    for (int k_index = 0; k_index < 1; k_index++) {
        int retrived_data_num = 0;

        for (int i = 0; i < query_size; i++)
        {
            for (int j = 0; j < 10; j++)
            {
                for (int z = 0; z < 10; z++) {
                    if (queryknn_results[i][j] == gt[i][z]) {
                        retrived_data_num++;
                        break;
                    }
                }
            }
        }
        float ratio = 0.0f;
        for (int i = 0; i < query_size; i++)
        {
            for (int j = 0; j < 10; j++)
            {
                float groundtruth_square_dist = euclidean_distance(querypoints[i], dataset[gt[i][j]], data_dimensionality);
                float otbained_square_dist = euclidean_distance(querypoints[i], dataset[queryknn_results[i][j]], data_dimensionality);
                if (groundtruth_square_dist == 0) {
                    ratio += 1.0f;
                } else {
                    ratio += sqrt(otbained_square_dist) / sqrt(groundtruth_square_dist);
                }
            }
        }

        float recall_value = float(retrived_data_num) / (query_size * 10);
        float overall_ratio = ratio / (query_size * 10);

        cout << "When k = " << 10 << ", (recall, ratio) = (" << recall_value << ", " << overall_ratio << ")" << endl;
    }
}