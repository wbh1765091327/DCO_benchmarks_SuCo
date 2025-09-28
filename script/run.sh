#!/bin/bash

cd "$(dirname "$0")/.." || exit 1
# 基础参数设置
K_SIZE=10
CANDIDATE_RATIO=0.005
COLLISION_RATIO=0.05
KMEANS_NUM_CENTROID=50
KMEANS_NUM_ITERS=2

# 数据集配置
declare -A datasets
# datasets["contriever-768"]="768"
# datasets["glove-200-angular"]="200"
# datasets["sift-128-euclidean"]="128"
# datasets["gist-960-euclidean"]="960"
# datasets["deep-image-96-angular"]="96"
# datasets["instructorxl-arxiv-768"]="768"
# datasets["openai-1536-angular"]="1536"
# datasets["msong-420"]="420"
datasets["glove-25-angular_100k"]="25"
datasets["glove-50-angular_100k"]="50"
datasets["glove-100-angular_100k"]="100"
datasets["glove-200-angular_100k"]="200"
# 子空间配置
declare -A subspace_configs
# subspace_configs["contriever-768"]="8:96"
# subspace_configs["glove-200-angular"]="10:20"
# subspace_configs["sift-128-euclidean"]="8:16"
# subspace_configs["gist-960-euclidean"]="8:120"
# subspace_configs["deep-image-96-angular"]="6:12"
# subspace_configs["instructorxl-arxiv-768"]="8:96"
# subspace_configs["openai-1536-angular"]="16:96"
# subspace_configs["msong-420"]="7:60"
subspace_configs["glove-25-angular_100k"]="5:5"
subspace_configs["glove-50-angular_100k"]="5:10"
subspace_configs["glove-100-angular_100k"]="5:20"
subspace_configs["glove-200-angular_100k"]="5:40"
# 创建结果目录
mkdir -p results

# 执行函数
run_suco() {
    local dataset=$1
    local dimensionality=$2
    local subspace_config=$3
    
    echo "=========================================="
    echo "Running SuCo on dataset: $dataset"
    echo "Dimensionality: $dimensionality"
    echo "Subspace config: $subspace_config"
    echo "=========================================="
    
    # 解析子空间配置 (格式: subspace_num:subspace_dim)
    local subspace_num=$(echo $subspace_config | cut -d':' -f1)
    local subspace_dim=$(echo $subspace_config | cut -d':' -f2)
    
    # 构建文件路径
    # 使用正确的命名格式
    local dataset_path="./data/$dataset/${dataset}_base.fvecs"
    local query_path="./data/$dataset/${dataset}_query.fvecs"
    local groundtruth_path="./data/$dataset/${dataset}_groundtruth.ivecs"
    local index_path="./index/$dataset/${dataset}_index.bin"  # 修改为文件路径
    mkdir -p $index_path
    
    if [ $dataset == "glove-200-angular" ]; then
        DATASET_SIZE=1183514
        QUERY_SIZE=10000
    elif [ $dataset == "sift-128-euclidean" ]; then
        DATASET_SIZE=1000000
        QUERY_SIZE=10000
    elif [ $dataset == "msong-420" ]; then
        DATASET_SIZE=983185
        QUERY_SIZE=1000
    elif [ $dataset == "contriever-768" ]; then
        DATASET_SIZE=990000
        QUERY_SIZE=10000
    elif [ $dataset == "gist-960-euclidean" ]; then
        DATASET_SIZE=1000000
        QUERY_SIZE=1000
    elif [ $dataset == "deep-image-96-angular" ]; then
        DATASET_SIZE=9990000
        QUERY_SIZE=10000
    elif [ $dataset == "instructorxl-arxiv-768" ]; then
        DATASET_SIZE=2253000
        QUERY_SIZE=1000
    elif [ $dataset == "openai-1536-angular" ]; then
        DATASET_SIZE=999000
        QUERY_SIZE=1000
    elif [ $dataset == "glove-25-angular_100k" ]; then
        DATASET_SIZE=100000
        QUERY_SIZE=1000
    elif [ $dataset == "glove-50-angular_100k" ]; then
        DATASET_SIZE=100000
        QUERY_SIZE=1000
    elif [ $dataset == "glove-100-angular_100k" ]; then
        DATASET_SIZE=100000
        QUERY_SIZE=1000
    elif [ $dataset == "glove-200-angular_100k" ]; then
        DATASET_SIZE=100000
        QUERY_SIZE=1000
    fi
    
    # 执行SuCo命令
    echo "Executing SuCo command..."
    echo "Command: ./suco --dataset-path $dataset_path --query-path $query_path --groundtruth-path $groundtruth_path --dataset-size $DATASET_SIZE --query-size $QUERY_SIZE --k-size $K_SIZE --data-dimensionality $dimensionality --subspace-dimensionality $subspace_dim --subspace-num $subspace_num --candidate-ratio $CANDIDATE_RATIO --collision-ratio $COLLISION_RATIO --kmeans-num-centroid $KMEANS_NUM_CENTROID --kmeans-num-iters $KMEANS_NUM_ITERS --index-path $index_path --load-index"
    
    # 执行命令并保存结果
    ./suco \
        --dataset-path "$dataset_path" \
        --query-path "$query_path" \
        --groundtruth-path "$groundtruth_path" \
        --dataset-size "$DATASET_SIZE" \
        --query-size "$QUERY_SIZE" \
        --k-size "$K_SIZE" \
        --data-dimensionality "$dimensionality" \
        --subspace-dimensionality "$subspace_dim" \
        --subspace-num "$subspace_num" \
        --candidate-ratio "$CANDIDATE_RATIO" \
        --collision-ratio "$COLLISION_RATIO" \
        --kmeans-num-centroid "$KMEANS_NUM_CENTROID" \
        --kmeans-num-iters "$KMEANS_NUM_ITERS" \
        --index-path "$index_path"  2>&1 | tee "results/${dataset}_${subspace_num}_${subspace_dim}.log"
    
    echo "Finished running $dataset with subspace_num=$subspace_num, subspace_dim=$subspace_dim"
    echo ""
}

# 主执行逻辑
main() {
    echo "Starting SuCo execution on all datasets..."
    echo "Base parameters:"
    echo "  Dataset size: $DATASET_SIZE"
    echo "  Query size: $QUERY_SIZE"
    echo "  K size: $K_SIZE"
    echo "  Candidate ratio: $CANDIDATE_RATIO"
    echo "  Collision ratio: $COLLISION_RATIO"
    echo "  K-means centroids: $KMEANS_NUM_CENTROID"
    echo "  K-means iterations: $KMEANS_NUM_ITERS"
    echo ""
    
    # 遍历所有数据集
    for dataset in "${!datasets[@]}"; do
        local dimensionality="${datasets[$dataset]}"
        local subspace_configs_str="${subspace_configs[$dataset]}"
        
        # 分割子空间配置字符串
        IFS=' ' read -ra configs <<< "$subspace_configs_str"
        
        # 对每个子空间配置运行SuCo
        for config in "${configs[@]}"; do
            run_suco "$dataset" "$dimensionality" "$config"
        done
    done
    
    echo "All SuCo executions completed!"
    echo "Results saved in ./results/ directory"
}

# 检查可执行文件
if [ ! -f "./suco" ]; then
    echo "Error: ./suco executable not found!"
    echo "Please make sure you have built the project and the executable is in the current directory."
    exit 1
fi

# 执行主函数
main