
import json
import os
from datetime import datetime

def load_version_config():
    """加载版本配置文件"""
    config_path = os.path.join(os.path.dirname(__file__), 'version_config.json')
    with open(config_path, 'r') as f:
        return json.load(f)

def save_version_config(config):
    """保存版本配置文件"""
    config_path = os.path.join(os.path.dirname(__file__), 'version_config.json')
    with open(config_path, 'w') as f:
        json.dump(config, f, indent=2)

def update_pubspec_version(version_string):
    """更新pubspec.yaml中的版本号"""
    pubspec_path = os.path.join(os.path.dirname(__file__), 'pubspec.yaml')
    with open(pubspec_path, 'r') as f:
        lines = f.readlines()

    for i, line in enumerate(lines):
        if line.strip().startswith('version:'):
            lines[i] = f'version: {version_string}\n'
            break

    with open(pubspec_path, 'w') as f:
        f.writelines(lines)

def increment_version(increment_type='build'):
    """
    增加版本号
    increment_type: 'major', 'minor', 'patch' 或 'build'
    """
    config = load_version_config()
    version = config['version']

    if increment_type == 'major':
        version['major'] += 1
        version['minor'] = 0
        version['patch'] = 0
        version['build'] = 0
    elif increment_type == 'minor':
        version['minor'] += 1
        version['patch'] = 0
        version['build'] = 0
    elif increment_type == 'patch':
        version['patch'] += 1
        version['build'] = 0
    else:  # 默认增加build号
        version['build'] += 1

    # 更新时间戳
    config['last_updated'] = datetime.now().isoformat()

    # 保存配置
    save_version_config(config)

    # 生成版本字符串
    version_string = f"{version['major']}.{version['minor']}.{version['patch']}+{version['build']}"

    # 更新pubspec.yaml
    update_pubspec_version(version_string)

    return version_string

if __name__ == '__main__':
    import sys

    # 默认增加build号
    increment_type = 'build'

    # 如果提供了参数，则使用参数指定的类型
    if len(sys.argv) > 1:
        increment_type = sys.argv[1]

    new_version = increment_version(increment_type)
    print(f"版本已更新至: {new_version}")
