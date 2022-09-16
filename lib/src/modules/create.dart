import 'dart:io';

import '../utils/utils.dart';

enum ModifyPlatform { all, iOS, android }

///app 模版的远程仓库地址
const String appTemplateUrl =
    'https://github.com/Ucoon/flutter_app_template.git';
const String templateName = 'kooboo_app_template';

///待替换的内容
const regProjectName = 'name: awesome_template';
const regDescription = 'description: Flutter template project.';
const regVersion = 'version: 1.0.0+1';

///需要修改的内容
String replaceDescription = '';
String replaceVersion = '';
String replaceAppName = '';

///创建项目
void create(
  String projectName,
  String packageName,
) {
  _create(projectName, packageName);
}

void _create(
  String projectName,
  String? packageName,
) {
  Directory current = Directory.current;
  Directory targetDir = Directory('${current.path}\\$projectName');
  if (targetDir.existsSync()) {
    String action = select(
      message: 'Target directory ${targetDir.path} already exists. you can:',
      options: ['override', 'cancel'],
    );
    if (action == 'override') {
      print('\nRemoving ${blue(targetDir)}...\n');
      targetDir.deleteSync(recursive: true);
    } else {
      return;
    }
  }

  ///设置包名
  if (packageName == null || packageName.isEmpty) {
    packageName = input(
      message:
          '1、The organization responsible for your new Flutter project, in reverse domain name notation. This string is used in Java package names and as prefix in the iOS bundle identifier.',
      defaultValue: 'com.example',
    );
  }

  ///设置开发语言
  String iOSLanguage = select(
    message: '2、Please select iOS programming language',
    options: ['objc', 'swift'],
  );
  String androidLanguage = select(
    message: '3、Please select Android programming language',
    options: ['java', 'kotlin'],
  );

  ///设置项目描述
  String description = input(
    message: '4、Please input your project description',
    defaultValue: 'a new Flutter project created by kooboo_app_cli',
  );

  ///设置项目版本
  String version = input(
    message: '5、Please input your project version',
    defaultValue: '1.0.0',
  );

  ///设置app名称
  String appName = input(
    message: '6、Please input your app name',
    defaultValue: projectName,
  );
  replaceDescription = description;
  replaceVersion = version;
  replaceAppName = appName;

  List<String> flutterArgs = _createFlutterArgs(
      projectName, packageName, androidLanguage, iOSLanguage, description);
  print('\n👉 Creating project in ${blue(targetDir.path)}\n');
  Process.start('flutter', flutterArgs, runInShell: true).then((process) {
    stdout.addStream(process.stdout);
    stderr.addStream(process.stderr);
    process.exitCode.then((value) {
      if (value == 0) {
        _fetchTemplateProject(projectName, packageName!, targetDir);
      }
    });
  });
}

///flutter 命令参数
List<String> _createFlutterArgs(
  String projectName,
  String packageName,
  String androidLanguage,
  String iOSLanguage,
  String description,
) {
  List<String> flutterArgs = <String>['create'];
  flutterArgs.add('--no-pub');
  flutterArgs.addAll(['--org', packageName]);
  flutterArgs.addAll(['-a', androidLanguage]);
  flutterArgs.addAll(['-i', iOSLanguage]);
  flutterArgs.addAll(['--description', description]);
  flutterArgs.add(projectName);
  return flutterArgs;
}

///下载模板文件
void _fetchTemplateProject(
    String projectName, String packageName, Directory targetDir) {
  print('\n👉 Download template from git repository...\n');
  Process.start('git', ['clone', appTemplateUrl, templateName],
          workingDirectory: targetDir.path)
      .then((process) {
    stdout.addStream(process.stdout);
    stderr.addStream(process.stderr);
    process.exitCode.then((value) {
      if (value == 0) {
        print('\n👉 Generate template...\n');
        _generateTargetFiles(
          projectName: projectName,
          filePath: '${targetDir.path}\\$templateName',
        );
        _updateTargetFiles(
          projectName: projectName,
          targetDir: targetDir.path,
        );
        _modifyTargetFiles(
          projectName: projectName,
          packageName: packageName,
          targetDir: targetDir.path,
        );
      }
    });
  });
}

///模板生成文件
void _generateTargetFiles({
  required String projectName,
  required String filePath,
}) {
  List<FileSystemEntity> files = Directory(filePath).listSync();
  for (FileSystemEntity entity in files) {
    FileSystemEntityType type = entity.statSync().type;
    String path = entity.path.split('\\').last;
    if (type == FileSystemEntityType.file) {
      if (entity.path.endsWith('.dart')) {
        _replace(
          path: entity.path,
          regex: templateName,
          replace: projectName,
        );
      }
      if (path == 'pubspec.yaml') {
        _replace(
          path: entity.path,
          regex: regProjectName,
          replace: 'name: $projectName',
        );
        _replace(
          path: entity.path,
          regex: regDescription,
          replace: 'description: $replaceDescription',
        );
        _replace(
          path: entity.path,
          regex: regVersion,
          replace: 'version: $replaceVersion+1',
        );
      }
    } else if (type == FileSystemEntityType.directory) {
      _generateTargetFiles(projectName: projectName, filePath: entity.path);
    }
  }
}

///配置文件
void _modifyTargetFiles({
  required String projectName,
  required String packageName,
  required String targetDir,
}) {
  print('\n👉 Generate Android configuration \n');
  if (replaceAppName != projectName) {
    modifyAppName(replaceAppName, ModifyPlatform.all,
        targetDir: Directory(targetDir));
  }
  _modifyAndroidPackageName(packageName, Directory(targetDir));
  print(green('\n👉  Generate ios configuration \n'));
  configIOSInfo(Directory(targetDir));
}

///更新文件
void _updateTargetFiles({
  required String projectName,
  required String targetDir,
}) {
  //覆盖lib
  Directory targetDirLib = Directory('$targetDir\\lib');
  targetDirLib.deleteSync(recursive: true);
  Directory targetDirCode = Directory('$targetDir\\$templateName\\lib');
  targetDirCode.renameSync('$targetDir\\lib');

  //覆盖pubspec.yaml
  Directory targetDirPub = Directory('$targetDir\\pubspec.yaml');
  targetDirPub.deleteSync(recursive: true);
  File targetDirTempPub = File('$targetDir\\$templateName\\pubspec.yaml');
  targetDirTempPub.renameSync('$targetDir\\pubspec.yaml');

  //覆盖gitignore
  Directory targetDirGit = Directory('$targetDir\\.gitignore');
  targetDirGit.deleteSync(recursive: true);
  File targetDirTempGit = File('$targetDir\\$templateName\\.gitignore');
  targetDirTempGit.renameSync('$targetDir\\.gitignore');

  //覆盖build.gradle(project)
  File targetDirBuild = File('$targetDir\\android\\build.gradle');
  targetDirBuild.deleteSync(recursive: true);
  File targetDirTempBuild =
      File('$targetDir\\$templateName\\android\\build.gradle');
  targetDirTempBuild.renameSync('$targetDir\\android\\build.gradle');

  //覆盖build.gradle(app)
  File targetDirAppBuild = File('$targetDir\\android\\app\\build.gradle');
  targetDirAppBuild.deleteSync(recursive: true);
  File targetDirTempAppBuild =
      File('$targetDir\\$templateName\\android\\app\\build.gradle');
  targetDirTempAppBuild.renameSync('$targetDir\\android\\app\\build.gradle');

  //覆盖AndroidManifest.xml
  File targetDirManifest =
      File('$targetDir\\android\\app\\src\\main\\AndroidManifest.xml');
  targetDirManifest.deleteSync(recursive: true);
  File targetDirTempManifest = File(
      '$targetDir\\$templateName\\android\\app\\src\\main\\AndroidManifest.xml');
  targetDirTempManifest
      .renameSync('$targetDir\\android\\app\\src\\main\\AndroidManifest.xml');

  //增加android混淆文件
  File targetDirTempProguard =
      File('$targetDir\\$templateName\\android\\app\\app-proguard-rules.pro');
  targetDirTempProguard
      .renameSync('$targetDir\\android\\app\\app-proguard-rules.pro');

  //增加推送混淆文件
  File targetDirTempAliProguard = File(
      '$targetDir\\$templateName\\android\\app\\ali-push-proguard-rules.pro');
  targetDirTempAliProguard
      .renameSync('$targetDir\\android\\app\\ali-push-proguard-rules.pro');

  //增加多渠道配置文件
  File targetDirConfig =
      File('$targetDir\\$templateName\\android\\config.json');
  targetDirConfig.renameSync('$targetDir\\android\\config.json');

  Directory targetDirTemp = Directory('$targetDir\\$templateName');
  targetDirTemp.deleteSync(recursive: true);

  print(green('\n👉 flutter pub get \n'));

  Process.start('flutter', ['pub', 'get'],
          workingDirectory: targetDir, runInShell: true)
      .then((process) {
    stdout.addStream(process.stdout);
    stderr.addStream(process.stderr);
    process.exitCode.then((value) {
      if (value == 0) {
        print('\n🎉 Successfully created project ${blue(projectName)}');
        print('👉 Get started with the following commands:\n');
        print('\$ ${green('cd $projectName')}');
        print('\$ ${green('flutter run\n\n')}');
        print(white('enjoy it ~'));
      }
    });
  });
}

void _replace({
  required String path,
  String regex = '',
  String replace = '',
}) {
  File file = File(path);
  if (file.existsSync()) {
    List<String> data = file.readAsLinesSync();
    bool containsUpdate = false;
    List<String> newData = data.map((line) {
      if (line.contains(regex)) {
        containsUpdate = true;
        return line.replaceAll(regex, replace);
      } else {
        return line;
      }
    }).toList();
    if (containsUpdate) {
      file.writeAsStringSync('${newData.join('\n')}\n');
    }
  }
}

///修改App名称
void modifyAppName(
  String appName,
  ModifyPlatform platform, {
  Directory? targetDir,
}) {
  targetDir = targetDir ?? Directory.current;
  print('Modify app name --> ${green(appName)}\n');
  switch (platform) {
    case ModifyPlatform.all:
      _modifyIOSAppName(appName, targetDir);
      _modifyAndroidAppName(appName, targetDir);
      break;
    case ModifyPlatform.iOS:
      _modifyIOSAppName(appName, targetDir);
      break;
    case ModifyPlatform.android:
      _modifyAndroidAppName(appName, targetDir);
      break;
    default:
  }
}

void _modifyIOSAppName(String appName, Directory targetDir) {
  Directory directory = Directory('${targetDir.path}\\ios\\Runner');
  File file = File('${directory.path}\\Info.plist');
  if (file.existsSync()) {
    try {
      List lines = file.readAsStringSync().split('\n');
      for (int i = 0; i < lines.length; i++) {
        String line = lines[i];
        if (line.contains("<key>CFBundleName</key>")) {
          lines[i + 1] = "\t<string>$appName</string>\r";
          break;
        }
      }
      print('✨ Successfully modify iOS app name \n');
      file.writeAsStringSync(lines.join('\n'));
    } catch (e) {
      print(red('Failed to read Info.plist file'));
    }
  } else {
    print(red('Info.plist not found.'));
  }
}

void _modifyAndroidAppName(String appName, Directory targetDir) {
  Directory directory = Directory('${targetDir.path}\\android\\app\\src\\main');
  String filePath = '${directory.path}\\AndroidManifest.xml';
  File file = File(filePath);
  if (file.existsSync()) {
    try {
      List lines = file.readAsStringSync().split('\n');
      for (int i = 0; i < lines.length; i++) {
        String line = lines[i];
        if (line.contains("android:label")) {
          lines[i] = "        android:label=\"$appName\"";
          break;
        }
      }
      print('✨ Successfully modify android app name \n');
      file.writeAsStringSync(lines.join('\n'));
    } catch (e) {
      print(red('Failed to read AndroidManifest.xml file'));
    }
  } else {
    print(red('AndroidManifest.xml not found'));
  }
}

void _modifyAndroidPackageName(String packageName, Directory targetDir) {
  String filePath = '${targetDir.path}\\android\\app\\build.gradle';
  File file = File(filePath);
  if (file.existsSync()) {
    try {
      List lines = file.readAsStringSync().split('\n');
      for (int i = 0; i < lines.length; i++) {
        String line = lines[i];
        if (line.contains("applicationId")) {
          lines[i] = "applicationId \"$packageName\"";
          break;
        }
      }
      print('✨ Successfully modify android package name \n');
      file.writeAsStringSync(lines.join('\n'));
    } catch (e) {
      print(red('Failed to read build.gradle file'));
    }
  } else {
    print(red('build.gradle not found'));
  }
}

///增加 iOS语言设置
void configIOSInfo(Directory targetDir) {
  Directory directory = Directory('${targetDir.path}\\ios\\Runner');
  File file = File('${directory.path}\\Info.plist');
  if (file.existsSync()) {
    try {
      List lines = file.readAsStringSync().split('\n');
      for (int i = 0; i < lines.length; i++) {
        String line = lines[i];
        if (line.contains("<dict>")) {
          lines.insert(i + 1, '''
	<key>CFBundleLocalizations</key>
	<array>
    	<string>en</string>
    	<string>zh_CN</string>
	</array>
  ''');
          break;
        }
      }
      print('✨ Successfully modify \n');
      file.writeAsStringSync(lines.join('\n'));
    } catch (e) {
      print(red('Failed to read Info.plist file'));
    }
  } else {
    print(red('Info.plist not found.'));
  }
}
