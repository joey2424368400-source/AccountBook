import SwiftUI

struct RegisterView: View {
    @Environment(AuthViewModel.self) private var auth
    @State private var isSecure = true
    @State private var isConfirmSecure = true

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 标题
                VStack(spacing: 8) {
                    Text("创建账号")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.primary)
                    Text("注册后可将数据备份到云端")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)

                // 表单
                VStack(spacing: 14) {
                    // 昵称
                    VStack(alignment: .leading, spacing: 6) {
                        Text("昵称（选填）")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        TextField("请输入昵称", text: Bindable(auth).displayName)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }

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
                                SecureField("至少6个字符", text: Bindable(auth).password)
                                    .textContentType(.newPassword)
                            } else {
                                TextField("至少6个字符", text: Bindable(auth).password)
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

                    // 确认密码
                    VStack(alignment: .leading, spacing: 6) {
                        Text("确认密码")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        HStack {
                            if isConfirmSecure {
                                SecureField("请再次输入密码", text: Bindable(auth).confirmPassword)
                            } else {
                                TextField("请再次输入密码", text: Bindable(auth).confirmPassword)
                            }
                            Button {
                                isConfirmSecure.toggle()
                            } label: {
                                Image(systemName: isConfirmSecure ? "eye.slash" : "eye")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }

                    if !auth.confirmPassword.isEmpty && auth.password != auth.confirmPassword {
                        Text("两次密码输入不一致")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }
                }

                // 错误提示
                if let error = auth.errorMessage {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // 注册按钮
                Button {
                    Task { await auth.register() }
                } label: {
                    ZStack {
                        Text("注册")
                            .font(.system(size: 16, weight: .semibold))
                            .opacity(auth.isLoading ? 0 : 1)
                        if auth.isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(auth.canRegister ? Color.blue : Color.gray.opacity(0.3))
                    .foregroundColor(auth.canRegister ? .white : .gray)
                    .cornerRadius(12)
                }
                .disabled(!auth.canRegister || auth.isLoading)

                // 登录入口
                HStack(spacing: 4) {
                    Text("已有账号？")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    NavigationLink("登录") {
                        LoginView()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
        }
        .navigationBarHidden(true)
    }
}
