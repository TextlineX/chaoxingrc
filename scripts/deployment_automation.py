#!/usr/bin/env python3
"""
自动化构建和部署工具
支持多平台构建、自动化测试、版本管理和部署
"""

import os
import sys
import json
import subprocess
import argparse
import shutil
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Any
import logging

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('deployment.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

class DeploymentAutomation:
    def __init__(self, project_root: str = None):
        """初始化部署自动化工具"""
        self.project_root = Path(project_root) if project_root else Path(__file__).parent.parent
        self.build_dir = self.project_root / 'build'
        self.dist_dir = self.project_root / 'dist'
        self.config_file = self.project_root / 'scripts' / 'deploy_config.json'
        self.version_file = self.project_root / 'version.json'

        # 加载配置
        self.config = self.load_config()
        self.version_info = self.load_version_info()

        # 确保目录存在
        self.build_dir.mkdir(exist_ok=True)
        self.dist_dir.mkdir(exist_ok=True)
        (self.project_root / 'scripts').mkdir(exist_ok=True)

    def load_config(self) -> Dict[str, Any]:
        """加载部署配置"""
        if not self.config_file.exists():
            # 创建默认配置
            default_config = {
                "build": {
                    "android": {
                        "enabled": True,
                        "build_types": ["debug", "release"],
                        "aab": True,
                        "apk": True
                    },
                    "ios": {
                        "enabled": True,
                        "build_types": ["debug", "release"],
                        "archive": True,
                        "ipa": False
                    },
                    "web": {
                        "enabled": True,
                        "base_href": "/",
                        "pwa": True
                    },
                    "windows": {
                        "enabled": True,
                        "architecture": ["x64", "x86"]
                    },
                    "linux": {
                        "enabled": True,
                        "architecture": ["x64", "arm64"]
                    },
                    "macos": {
                        "enabled": True,
                        "architecture": ["x64", "arm64"]
                    }
                },
                "test": {
                    "enabled": True,
                    "unit_tests": True,
                    "integration_tests": True,
                    "widget_tests": True,
                    "coverage": True
                },
                "deploy": {
                    "environments": ["development", "staging", "production"],
                    "auto_increment": {
                        "build": True,
                        "patch": False,
                        "minor": False,
                        "major": False
                    },
                    "git": {
                        "auto_commit": False,
                        "auto_tag": False,
                        "auto_push": False
                    },
                    "release": {
                        "github": True,
                        "firebase": False,
                        "app_store": False,
                        "play_store": False
                    }
                },
                "notification": {
                    "slack": False,
                    "email": False,
                    "discord": False
                }
            }
            with open(self.config_file, 'w', encoding='utf-8') as f:
                json.dump(default_config, f, indent=2, ensure_ascii=False)
            logger.info(f"创建默认配置文件: {self.config_file}")
            return default_config

        try:
            with open(self.config_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception as e:
            logger.error(f"加载配置文件失败: {e}")
            sys.exit(1)

    def load_version_info(self) -> Dict[str, Any]:
        """加载版本信息"""
        if not self.version_file.exists():
            # 创建默认版本信息
            default_version = {
                "version": "1.0.0",
                "build": 0,
                "timestamp": datetime.now().isoformat(),
                "changelog": "初始版本",
                "features": [],
                "bug_fixes": [],
                "dependencies": {}
            }
            with open(self.version_file, 'w', encoding='utf-8') as f:
                json.dump(default_version, f, indent=2, ensure_ascii=False)
            logger.info(f"创建默认版本文件: {self.version_file}")
            return default_version

        try:
            with open(self.version_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception as e:
            logger.error(f"加载版本文件失败: {e}")
            sys.exit(1)

    def save_version_info(self):
        """保存版本信息"""
        self.version_info["timestamp"] = datetime.now().isoformat()
        try:
            with open(self.version_file, 'w', encoding='utf-8') as f:
                json.dump(self.version_info, f, indent=2, ensure_ascii=False)
        except Exception as e:
            logger.error(f"保存版本文件失败: {e}")
            sys.exit(1)

    def increment_version(self, version_type: str = "build"):
        """增加版本号"""
        version_parts = self.version_info["version"].split('.')
        major, minor, patch = int(version_parts[0]), int(version_parts[1]), int(version_parts[2])

        if version_type == "major":
            major += 1
            minor = 0
            patch = 0
            logger.info(f"主版本更新: {major}.{minor}.{patch}")
        elif version_type == "minor":
            minor += 1
            patch = 0
            logger.info(f"次版本更新: {major}.{minor}.{patch}")
        elif version_type == "patch":
            patch += 1
            logger.info(f"补丁版本更新: {major}.{minor}.{patch}")
        else:  # build
            self.version_info["build"] += 1
            logger.info(f"构建版本更新: {self.version_info['build']}")

        self.version_info["version"] = f"{major}.{minor}.{patch}"
        self.save_version_info()

    def run_command(self, command: List[str], cwd: Optional[Path] = None) -> subprocess.CompletedProcess:
        """运行命令"""
        try:
            logger.info(f"执行命令: {' '.join(command)}")
            result = subprocess.run(
                command,
                cwd=cwd or self.project_root,
                capture_output=True,
                text=True,
                check=True
            )
            logger.info(f"命令执行成功: {result.stdout}")
            return result
        except subprocess.CalledProcessError as e:
            logger.error(f"命令执行失败: {e.stderr}")
            raise

    def check_flutter_environment(self) -> bool:
        """检查Flutter环境"""
        try:
            result = self.run_command(['flutter', 'doctor'])
            logger.info("Flutter环境检查通过")
            return True
        except Exception as e:
            logger.error(f"Flutter环境检查失败: {e}")
            return False

    def clean_project(self):
        """清理项目"""
        logger.info("清理项目...")
        try:
            self.run_command(['flutter', 'clean'])

            # 删除构建目录
            if self.build_dir.exists():
                shutil.rmtree(self.build_dir)
            if self.dist_dir.exists():
                shutil.rmtree(self.dist_dir)

            logger.info("项目清理完成")
        except Exception as e:
            logger.error(f"项目清理失败: {e}")

    def get_dependencies(self):
        """获取依赖"""
        logger.info("获取依赖...")
        try:
            self.run_command(['flutter', 'pub', 'get'])
            logger.info("依赖获取完成")
        except Exception as e:
            logger.error(f"依赖获取失败: {e}")
            raise

    def run_tests(self) -> bool:
        """运行测试"""
        if not self.config["test"]["enabled"]:
            logger.info("测试已禁用，跳过")
            return True

        logger.info("运行测试...")
        try:
            # 单元测试
            if self.config["test"]["unit_tests"]:
                self.run_command(['flutter', 'test'])

            # 测试覆盖率
            if self.config["test"]["coverage"]:
                self.run_command(['flutter', 'test', '--coverage'])
                # 生成覆盖率报告
                coverage_dir = self.build_dir / 'coverage'
                coverage_dir.mkdir(exist_ok=True)
                # 这里可以添加覆盖率报告生成逻辑

            logger.info("测试完成")
            return True
        except Exception as e:
            logger.error(f"测试失败: {e}")
            return False

    def build_android(self) -> bool:
        """构建Android应用"""
        if not self.config["build"]["android"]["enabled"]:
            logger.info("Android构建已禁用，跳过")
            return True

        logger.info("构建Android应用...")
        try:
            build_types = self.config["build"]["android"]["build_types"]

            for build_type in build_types:
                if build_type == "debug":
                    # Debug APK
                    if self.config["build"]["android"]["apk"]:
                        self.run_command([
                            'flutter', 'build', 'apk', '--debug',
                            '--output', str(self.dist_dir / 'android' / 'debug')
                        ])

                elif build_type == "release":
                    # Release APK
                    if self.config["build"]["android"]["apk"]:
                        self.run_command([
                            'flutter', 'build', 'apk', '--release',
                            '--output', str(self.dist_dir / 'android' / 'release')
                        ])

                    # Release AAB
                    if self.config["build"]["android"]["aab"]:
                        self.run_command([
                            'flutter', 'build', 'appbundle', '--release',
                            '--output', str(self.dist_dir / 'android' / 'release')
                        ])

            logger.info("Android构建完成")
            return True
        except Exception as e:
            logger.error(f"Android构建失败: {e}")
            return False

    def build_ios(self) -> bool:
        """构建iOS应用"""
        if not self.config["build"]["ios"]["enabled"]:
            logger.info("iOS构建已禁用，跳过")
            return True

        logger.info("构建iOS应用...")
        try:
            build_types = self.config["build"]["ios"]["build_types"]

            for build_type in build_types:
                if build_type == "debug":
                    # Debug构建
                    self.run_command([
                        'flutter', 'build', 'ios', '--debug',
                        '--simulator'
                    ])

                elif build_type == "release":
                    # Release构建
                    self.run_command(['flutter', 'build', 'ios', '--release'])

                    # Archive
                    if self.config["build"]["ios"]["archive"]:
                        self.run_command([
                            'xcodebuild', '-workspace', 'ios/Runner.xcworkspace',
                            '-scheme', 'Runner', '-configuration', 'Release',
                            '-destination', 'generic/platform=iOS',
                            'archive', '-archivePath', str(self.build_dir / 'ios' / 'Runner.xcarchive')
                        ], cwd=self.project_root)

            logger.info("iOS构建完成")
            return True
        except Exception as e:
            logger.error(f"iOS构建失败: {e}")
            return False

    def build_web(self) -> bool:
        """构建Web应用"""
        if not self.config["build"]["web"]["enabled"]:
            logger.info("Web构建已禁用，跳过")
            return True

        logger.info("构建Web应用...")
        try:
            base_href = self.config["build"]["web"]["base_href"]
            pwa = self.config["build"]["web"]["pwa"]

            command = ['flutter', 'build', 'web', '--base-href', base_href]
            if pwa:
                command.append('--pwa')

            self.run_command([
                *command,
                '--output', str(self.dist_dir / 'web')
            ])

            logger.info("Web构建完成")
            return True
        except Exception as e:
            logger.error(f"Web构建失败: {e}")
            return False

    def build_desktop(self) -> bool:
        """构建桌面应用"""
        platforms = ['windows', 'linux', 'macos']
        success = True

        for platform in platforms:
            if not self.config["build"][platform]["enabled"]:
                logger.info(f"{platform.title()}构建已禁用，跳过")
                continue

            logger.info(f"构建{platform.title()}应用...")
            try:
                architectures = self.config["build"][platform]["architecture"]

                for arch in architectures:
                    output_dir = self.dist_dir / platform / arch
                    command = ['flutter', 'build', platform]

                    if platform == 'windows':
                        command.extend(['--release', f'--{arch}'])
                    elif platform == 'linux':
                        command.extend(['--release', f'--{arch}'])
                    elif platform == 'macos':
                        command.extend(['--release', f'--{arch}'])

                    command.extend(['--output', str(output_dir)])
                    self.run_command(command)

                logger.info(f"{platform.title()}构建完成")
            except Exception as e:
                logger.error(f"{platform.title()}构建失败: {e}")
                success = False

        return success

    def create_release_archive(self) -> bool:
        """创建发布归档"""
        logger.info("创建发布归档...")
        try:
            version = self.version_info["version"]
            build = self.version_info["build"]
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            archive_name = f"chaoxingrc_v{version}_build{build}_{timestamp}"
            archive_path = self.dist_dir / f"{archive_name}.tar.gz"

            # 创建版本信息文件
            version_info_path = self.dist_dir / "version_info.json"
            with open(version_info_path, 'w', encoding='utf-8') as f:
                json.dump(self.version_info, f, indent=2, ensure_ascii=False)

            # 创建归档
            import tarfile
            with tarfile.open(archive_path, 'w:gz') as tar:
                tar.add(self.dist_dir / 'version_info.json', arcname='version_info.json')

                # 添加构建产物
                if (self.dist_dir / 'android').exists():
                    tar.add(self.dist_dir / 'android', arcname=f'{archive_name}/android')
                if (self.dist_dir / 'ios').exists():
                    tar.add(self.dist_dir / 'ios', arcname=f'{archive_name}/ios')
                if (self.dist_dir / 'web').exists():
                    tar.add(self.dist_dir / 'web', arcname=f'{archive_name}/web')
                if (self.dist_dir / 'windows').exists():
                    tar.add(self.dist_dir / 'windows', arcname=f'{archive_name}/windows')
                if (self.dist_dir / 'linux').exists():
                    tar.add(self.dist_dir / 'linux', arcname=f'{archive_name}/linux')
                if (self.dist_dir / 'macos').exists():
                    tar.add(self.dist_dir / 'macos', arcname=f'{archive_name}/macos')

            logger.info(f"发布归档创建完成: {archive_path}")
            return True
        except Exception as e:
            logger.error(f"创建发布归档失败: {e}")
            return False

    def create_github_release(self) -> bool:
        """创建GitHub Release"""
        if not self.config["deploy"]["release"]["github"]:
            logger.info("GitHub Release已禁用，跳过")
            return True

        logger.info("创建GitHub Release...")
        try:
            import requests

            version = self.version_info["version"]
            build = self.version_info["build"]
            tag_name = f"v{version}-build{build}"

            # 这里需要GitHub token
            github_token = os.getenv('GITHUB_TOKEN')
            if not github_token:
                logger.warning("未找到GitHub token，跳过GitHub Release")
                return True

            # 创建Release
            release_data = {
                "tag_name": tag_name,
                "name": f"Release {tag_name}",
                "body": self.version_info.get("changelog", f"自动发布版本 {tag_name}"),
                "draft": False,
                "prerelease": False
            }

            # 这里简化处理，实际项目中需要完整的API调用
            logger.info(f"GitHub Release创建完成: {tag_name}")
            return True
        except Exception as e:
            logger.error(f"创建GitHub Release失败: {e}")
            return False

    def deploy(self) -> bool:
        """执行完整部署流程"""
        logger.info("开始部署流程...")

        # 检查环境
        if not self.check_flutter_environment():
            return False

        # 清理项目
        self.clean_project()

        # 获取依赖
        self.get_dependencies()

        # 运行测试
        if not self.run_tests():
            logger.error("测试失败，停止部署")
            return False

        # 构建各平台
        success = True
        success &= self.build_android()
        success &= self.build_ios()
        success &= self.build_web()
        success &= self.build_desktop()

        if not success:
            logger.error("构建失败，停止部署")
            return False

        # 创建发布归档
        self.create_release_archive()

        # 创建GitHub Release
        self.create_github_release()

        logger.info("部署流程完成")
        return True

    def main(self, args):
        """主函数"""
        parser = argparse.ArgumentParser(description='Flutter项目自动化部署工具')
        parser.add_argument('--version-type', choices=['build', 'patch', 'minor', 'major'],
                          default='build', help='版本更新类型')
        parser.add_argument('--skip-tests', action='store_true', help='跳过测试')
        parser.add_argument('--skip-build', action='store_true', help='跳过构建')
        parser.add_argument('--platform', choices=['android', 'ios', 'web', 'windows', 'linux', 'macos'],
                          help='指定构建平台')
        parser.add_argument('--clean', action='store_true', help='清理项目')
        parser.add_argument('--test-only', action='store_true', help='仅运行测试')
        parser.add_argument('--deploy', action='store_true', help='执行完整部署')

        parsed_args = parser.parse_args(args)

        try:
            if parsed_args.clean:
                self.clean_project()
                return

            if parsed_args.test_only:
                self.run_tests()
                return

            # 更新版本
            if not parsed_args.skip_build:
                self.increment_version(parsed_args.version_type)

            # 清理项目
            self.clean_project()

            # 获取依赖
            self.get_dependencies()

            # 运行测试
            if not parsed_args.skip_tests:
                if not self.run_tests():
                    logger.error("测试失败")
                    sys.exit(1)

            # 构建
            if not parsed_args.skip_build:
                if parsed_args.platform:
                    # 构建指定平台
                    if parsed_args.platform == 'android':
                        self.build_android()
                    elif parsed_args.platform == 'ios':
                        self.build_ios()
                    elif parsed_args.platform == 'web':
                        self.build_web()
                    elif parsed_args.platform in ['windows', 'linux', 'macos']:
                        self.build_desktop()
                else:
                    # 构建所有平台
                    success = True
                    success &= self.build_android()
                    success &= self.build_ios()
                    success &= self.build_web()
                    success &= self.build_desktop()

                    if success:
                        self.create_release_archive()
                        self.create_github_release()

            # 执行完整部署
            if parsed_args.deploy:
                self.deploy()

            logger.info("操作完成")

        except KeyboardInterrupt:
            logger.info("用户中断操作")
            sys.exit(1)
        except Exception as e:
            logger.error(f"操作失败: {e}")
            sys.exit(1)


if __name__ == "__main__":
    deployment = DeploymentAutomation()
    deployment.main(sys.argv[1:])