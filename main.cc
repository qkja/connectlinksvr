
#include <iostream>
#include <string>
#include <grpcpp/grpcpp.h>
#include "protoc/health/health.grpc.pb.h" // 引入生成的头文件

using grpc::Server;
using grpc::ServerBuilder;
using grpc::ServerContext;
using grpc::Status;
using health::HealthReq;
using health::HealthRsp;
using health::HealthService;


class GreeterServiceImpl final : public HealthService::Service {
  // 重写 Health 方法
    Status Health(ServerContext* context, const HealthReq* request, HealthRsp* response) override{
    std::string prefix("Hello");
    // 构造回复消息
    response->set_code(prefix);
    std::cout << "Sending response: " << response->code()<< std::endl;
    return Status::OK; // 返回成功状态
  }
};

void RunServer() {
  std::string server_address("0.0.0.0:50051");
  GreeterServiceImpl service;

  ServerBuilder builder;
  // 监听端口并提供服务
  builder.AddListeningPort(server_address, grpc::InsecureServerCredentials());
  builder.RegisterService(&service);

  std::unique_ptr<Server> server(builder.BuildAndStart());
  std::cout << "Server listening on " << server_address << std::endl;
  server->Wait(); // 阻塞等待
}

int main(int argc, char** argv) {
  RunServer();
  return 0;
}
