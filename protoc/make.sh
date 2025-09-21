#!/bin/sh
#@auth qkj
#@time 20250921


SHELLPATH=$(cd `dirname $0`; pwd)
cd ${SHELLPATH}

function make_proto_go {
    filename=$1
    path=${SHELLPATH}/${filename}
    
    echo -e "\033[35m === 开始处理目录: ${path} === \033[0m"
    
    # 1. 检查目录是否存在
    if [ ! -d "${path}" ]; then
        echo -e "\033[31m 错误: 目录不存在 ${path} \033[0m"
        return 1
    fi
    
    # 2. 检查.proto文件是否存在
    proto_files=(${path}/*.proto)
    if [ ${#proto_files[@]} -eq 0 ]; then
        echo -e "\033[31m 错误: 在 ${path} 中未找到.proto文件 \033[0m"
        return 1
    fi
    
    echo -e "\033[32m 找到文件: ${proto_files[@]} \033[0m"
    
    # 3. 清理旧的验证文件
    find ${path} -name "*.pb.validate.go" -exec rm -f {} \;
    if [ $? != 0 ]; then
        echo -e "\033[31m 清理验证文件失败 \033[0m"
        return 1
    fi

    # 4. 检查是否已存在验证函数
    grep -rn "func.*Validate" ${path} > /dev/null 2>&1
    if [ $? != 0 ]; then
        echo -e "\033[33m 生成验证代码... \033[0m"
        # 使用数组传递文件参数，避免空格问题
        protoc -I. --proto_path="${path}" \
    --validate_out="lang=go:${path}" \
    --go_out="${path}" --go_opt=paths=source_relative \
    --go-grpc_out="${path}" --go-grpc_opt=paths=source_relative \
    "${proto_files[@]}"
    else
        echo -e "\033[33m 跳过验证代码生成... \033[0m"
        protoc -I. --proto_path="${path}" \
            --go_out="plugins=grpc:${path}" \
            "${proto_files[@]}"
    fi
    
    if [ $? != 0 ]; then
        echo -e "\033[31m --- ${path} 处理失败 --- \033[0m"
        return 1
    fi

    # 5. 生成gRPC-Gateway代码
    echo -e "\033[33m 生成gRPC-Gateway代码... \033[0m"
    protoc -I. --proto_path="${path}" \
        --grpc-gateway_out="allow_delete_body=true:${path}" \
        --grpc-gateway_opt logtostderr=true \
        --grpc-gateway_opt paths=source_relative \
        "${proto_files[@]}"
    
    if [ $? != 0 ]; then
        echo -e "\033[31m --- gRPC-Gateway代码生成失败 --- \033[0m"
        return 1
    fi
    
    echo -e "\033[32m === ${path} 处理完成 === \033[0m"
    md5sum ${path}/*.pb.go 2>/dev/null || true
}
function make_proto_c++ {
    filename=$1
    path=${SHELLPATH}/${filename}
    
    echo -e "\033[35m === 开始处理目录: ${path} === \033[0m"
    
    # 1. 检查目录是否存在
    if [ ! -d "${path}" ]; then
        echo -e "\033[31m 错误: 目录不存在 ${path} \033[0m"
        return 1
    fi
    
    # 2. 检查.proto文件是否存在
    proto_files=(${path}/*.proto)
    if [ ${#proto_files[@]} -eq 0 ]; then
        echo -e "\033[31m 错误: 在 ${path} 中未找到.proto文件 \033[0m"
        return 1
    fi
    
    echo -e "\033[32m 找到文件: ${proto_files[@]} \033[0m"
    
    # 3. 清理旧的验证文件
    find ${path} -name "*.pb.validate.go" -exec rm -f {} \;
    if [ $? != 0 ]; then
        echo -e "\033[31m 清理验证文件失败 \033[0m"
        return 1
    fi

    # 4. 检查是否已存在验证函数
    grep -rn "func.*Validate" ${path} > /dev/null 2>&1
    if [ $? != 0 ]; then
        echo -e "\033[33m 生成验证代码... \033[0m"
        # 使用数组传递文件参数，避免空格问题
        protoc -I. --proto_path="${path}" \
    --cpp_out="${path}"  \
    --grpc_out="${path}"  \
    --plugin=protoc-gen-grpc="/usr/local/bin/grpc_cpp_plugin" \
    "${proto_files[@]}"
    else
        echo -e "\033[33m 跳过验证代码生成... \033[0m"
    fi
    
    if [ $? != 0 ]; then
        echo -e "\033[31m --- ${path} 处理失败 --- \033[0m"
        return 1
    fi
    
    echo -e "\033[32m === ${path} 处理完成 === \033[0m"
    md5sum ${path}/*.pb.go 2>/dev/null || true
}

function make_go {

    # 验证切换结果
    files=$(ls .)
    for sfile in ${files}
    do  
        if [ -d "${sfile}" ] && [ "${sfile}" != "google" ] && [ "${sfile}" != "protoc-gen-openapiv2" ] && [ "${sfile}" != "validate" ] && [ "${sfile}" != "multidirectory" ]; then
            make_proto_go ${sfile}
            if [ $? != 0 ]; then
                echo -e "\033[31m --- make ${sfile} fail. --- \033[0m"
                exit 1
            fi
        fi
    done
}
function make_c++ {

    # 验证切换结果
    files=$(ls .)
    for sfile in ${files}
    do  
        if [ -d "${sfile}" ] && [ "${sfile}" != "google" ] && [ "${sfile}" != "protoc-gen-openapiv2" ] && [ "${sfile}" != "validate" ] && [ "${sfile}" != "multidirectory" ]; then
            make_proto_c++ ${sfile}
            if [ $? != 0 ]; then
                echo -e "\033[31m --- make ${sfile} fail. --- \033[0m"
                exit 1
            fi
        fi
    done
}


function main {
    echo -e "\033[34m ######################### sh make.sh $1 $2 ######################### \033[0m"
    case $1 in
            "-go")
                make_go
            ;;
            "-c++")
                make_c++
            ;;
            esac
}

main $@