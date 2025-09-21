TARGET := "openplatformsvr"
BRANCH := "main"
DATE := $(shell date +%Y%m%d)
BOOL := $(shell git ls-remote --heads git@github.com:qkja/sagrpcprotocol.git $(BRANCH))
PROTO_DEPENDS := "GatewayCommon" "Health" "Example"


# 编译器设置
CXX = g++
CXXFLAGS = -std=c++11
LDFLAGS = $(shell pkg-config --cflags --libs grpc++ grpc protobuf)

# 源文件和目标文件
SRCS = main.cc $(wildcard protoc/health/*.cc)
OBJS = $(SRCS:.cc=.o)
TARGET = server

.PHONY: all
# 默认目标
all: $(TARGET)

# 链接目标文件生成可执行文件
$(TARGET): $(OBJS)
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LDFLAGS)

# 编译源文件为目标文件
%.o: %.cc
	$(CXX) $(CXXFLAGS) -c $< -o $@

# 清理生成的文件
clean:
	rm -f $(OBJS) $(TARGET)

DOWNLOAD_PROTO:
	# 打印变量
	@ echo "分支名称:"$(BRANCH)
	@ echo "日期:"$(DATE)
	# 删除当前目录下的saprotoc
	@rm -rf ./sagrpcprotocol
	# 下载proto
	@if [ -n ${BOOL} ]; then \
	   echo "down protoc ==> main";\
       git clone -b main git@github.com:qkja/sagrpcprotocol.git;\
    else \
        echo "down protoc ==>"$(BRANCH);\
        git clone -b ${BRANCH} git@github.com:qkja/sagrpcprotocol.git;\
    fi;
	# 将proto拷贝到./protoc下面
	@for item in $(PROTO_DEPENDS); do \
		cp -rf  ./sagrpcprotocol/$$item/* ./protoc/; done
 	# 将make.sh拷贝到./protoc下面
	@cp -f ./sagrpcprotocol/make.sh ./protoc/
	# 立刻编译protoc
	@bash ./protoc/make.sh -c++