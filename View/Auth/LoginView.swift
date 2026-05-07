import SwiftUI

struct LoginView: View {
    @Environment(AuthViewModel.self) private var auth
    @State private var isSecure = true

    var body: some View {
        VStack(spacing: 28) {
            Spacer().frame(height: 60)

            // Logo 区域
            VStack(spacing: 12) {
                Image(systemName: "book.pages.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.blue)

                Text("记账")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)

                Text("管理您的每一笔账")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            Spacer().frame(height: 20)

            // 表单
            VStack(spacing: 16) {
                // 邮箱
                VStack(alignment: .leading, spacing: 6) {
                    Text("邮箱")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    TextField("请输入邮箱", text: Bindable(auth).email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }

                // 密码
                VStack(alignment: .leading, spacing: 6) {
                    Text("密码")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    HStack {
                        if isSecure {
                            SecureField("请输入密码", text: Bindable(auth).password)
                                .textContentType(.password)
                        } else {
                            TextField("请输入密码", text: Bindable(auth).password)
                        }
                        Button {
                            isSecure.toggle()
                        } label: {
                            Image(systemName: isSecure ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
            }

            // 错误提示
            if let error = auth.errorMessage {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // 登录按钮
            Button {
                Task { await auth.login() }
            } label: {
                ZStack {
                    Text("登录")
                        .font(.system(size: 16, weight: .semibold))
                        .opacity(auth.isLoading ? 0 : 1)
                    if auth.isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(auth.canLogin ? Color.blue : Color.gray.opacity(0.3))
                .foregroundColor(auth.canLogin ? .white : .gray)
                .cornerRadius(12)
            }
            .disabled(!auth.canLogin || auth.isLoading)

            // 注册入口
            HStack(spacing: 4) {
                Text("还没有账号？")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                NavigationLink("注册") {
                    RegisterView()
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.blue)
            }

            Spacer()
        }
        .padding(.horizontal, 28)
        .navigationBarHidden(true)
    }
}
