lib/
├── core/                   # 核心功能
│   ├── constants/         # 常量定义
│   ├── errors/           # 错误处理
│   ├── network/          # 网络相关
│   │   ├── api/         # API 接口
│   │   └── dio/         # Dio 配置
│   └── utils/           # 工具类
│
├── data/                  # 数据层
│   ├── models/          # 数据模型
│   ├── repositories/    # 数据仓库
│   └── local/           # 本地存储
│       ├── hive/        # Hive 数据库
│       ├── shared_prefs/ # SharedPreferences
│       └── secure_storage/ # 安全存储
│
├── features/              # 功能模块
│   ├── auth/            # 认证模块
│   │   ├── screens/     # 页面
│   │   ├── widgets/     # 组件
│   │   └── controllers/ # 控制器
│   ├── home/            # 首页模块
│   └── profile/         # 个人中心模块
│
├── routes/               # 路由管理
├── theme/               # 主题配置
├── widgets/             # 公共组件
└── main.dart            # 入口文件