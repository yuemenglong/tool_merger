# tool_merger

## 业务流程

1. 上半部分是project，下半部分是item
2. project点击create，弹出窗口，输入名称，点击确定，此时加入table中，output为空，且为选中状态
3. 当点击outputpath后面的select时候，出现选择文件夹的窗口，选择后赋值给outputpath
4. 当有选中状态的project时，从外部向窗口拖动文件/文件夹，则其路径加入到item里，name就是文件/文件夹的名字，path是全路径，拖进来默认enable
5. project的updatetime只有在item有变化时才更新
6. 以json形式保存project的数据，projects.json,只有按下generate时才更新当前project（也就是其他project如果有调整item，但是没有generate，则这个改动在内存里，不保存）
7. 删除都要弹出确认框，只要确认，立即保存。project的create也是立即保存，outputpath的修改不需要立即保存
8. 点击generate时，目的是将当前的item里的内容进行合并，生成一个xml文件，保存在<outputPath>/<name>.xml下
9. 生成算法参考doc/merge.cpp
