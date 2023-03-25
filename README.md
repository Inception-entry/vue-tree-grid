# 基于vue.js实现树形表格的封装（vue-tree-grid）

## 前言
> 由于公司产品（基于vue.js）需要，要实现一个[树形表格](https://github.com/Inception-entry/vue-tree-grid)的功能，百度、google找了一通，并没有发现很靠谱的，也不是很灵活。所以就用vue自己写了一个，还望大家多多指教。
#### 主要技术点：`vue子组件的递归实现及相关样式的实现`

## 路由讲解
- 根路由：拓展的内部表格数据过多, 是时间分片方式处理的
- /mobile: 手机上的树形表格
- /virtual: 拓展的内部表格数据过多, 是时间分片方式处理的(强烈建议用此方式)

## 树形表格实现
- 效果图([Demo](https://inception-entry.github.io/dist/#/))
- 主要代码
> index.vue页面实现业务逻辑代码，比如树表格上面的一些操作按钮的实现及数据获取。
>
``` html
<template>
  <div class="contains">
    <h1>树表格实现</h1>
    <tree-grid ref="recTree"
    :list.sync="treeDataSource"
    @handlerFold="handlerFold"
    @handlerExpand="handlerExpand"></tree-grid>
  </div>
</template>
<script>
import treeGrid from '@/components/tree-grid.vue'
export default {
  data() {
    return {
      list: [], // 请求原始数据
      treeDataSource: [] // 组合成树表格接收的数据
    }
  },
  components: {
    treeGrid
  },
  methods: {
    handlerFold(val) {
      console.log('展开/折叠')
    },
    handlerExpand(val) {
      console.log('扩展/收起');
    },
  }
}
</script>
```
``` bash
原始数据`list`：是不包含子数据的数据结构，即没有层级结构，例如：
[{id:111,parentId:0,name:'父及'},{id:111,parentId:111,name:'子级'}...]，通过parentId来获取对应父子层级结构
`treeDataSource`：是树表格需要的数据结构，例如：
[{id:0,name:'父及',children:[{id:10,name:'子级',children:[]}]},...]
```
> 如果后台返回给你的是原始数据格式，就可以用下面方法封装成树表格可以使用的数据结构：
``` bash
  getTreeData() {
    // 取父节点
    let parentArr = this.list.filter(l => l.parentId === 0)
    this.treeDataSource = this.getTreeData(this.list, parentArr)
  },
  // 这里处理没有children结构的数据
  getTreeData(list, dataArr) {
    dataArr.map((pNode, i) => {
      let childObj = []
      list.map((cNode, j) => {
        if (pNode.Id === cNode.parentId) {
          childObj.push(cNode)
        }
      })
      pNode.children = childObj
      if (childObj.length > 0) {
        this.getTreeData(list, childObj)
      }
    })
    return dataArr
  }
```
> tree-grid.vue页面。此页面是实现树表格的关健页面。主要代码如下：
``` html
<template>
	<div class="tree-grid">
		<div class="tree-head">
			<table>
				<tr>
					<td class="td1">组织名称</td>
					<td class="td2">子账号数量(个)</td>
					<td class="td3">操作</td>
				</tr>
			</table>
		</div>
		<div id="scrollWrap" class="tree-wrap">
			<div class="tree-body">
				<table v-if='treeDataSource.length>0'>
					<tbody>
						<tr>
							<td>
								<tree-unit
									v-for="(model,i) in treeDataSource"
                  :key="'root_node_'+i"
									:root="0"
									:num="i"
									:nodes="treeDataSource.length"
									:trees.sync="treeDataSource"
									:model.sync="model">
								</tree-unit>
							</td>
						</tr>
					</tbody>
				</table>
			</div>
		</div>
	</div>
</template>
```
首先这里的子组件`tree-unit`没有在页面上有引入，但是也可以正常使用。这里就是关健点，因为这个子组件是需要递归实现，所以，需要动态注册到当前组件中。代码如下（由于代码太多，先贴图说明吧，[点击这里](https://github.com/Inception-entry/vue-tree-grid/blob/master/src/components/tree-grid.vue)可以看源码）：
![](https://inception-entry.github.io/dist/nest.png)

这里子组件看起来是不是挺奇怪的，但是为了递归他本身，暂时也只想到这种办法。如果有更好的办法，欢迎留言指正。<br>
那么，树表格的结构实现在哪里呢？？对，就是在子组件的模版(`template`)里面，这里就不贴代码了，可以移步到[源码](https://github.com/Inception-entry/vue-tree-grid/blob/master/src/components/tree-grid.vue)查看。<br>

> 补充一点：不要只看js部分，css部分才是这个树表格的关健所在。当然里面我采用了大量的计算属性去判断各种样式的展示，还有一种方法，就是在`initTreeData`方法里面去实现，这个方法就是处理或添加一些我们树表格所使用的信息。比如我现在在里面实现的层级线的偏移量`m.bLeft = level === 1 ? 65 : (level - 2) * 14 + 65` 这个计算如果没有看明白，可以留言。

最后，如有问题，还请多多包含，多多指教！！！顺便给我好久没有更新的博客打个广告,
欢迎点击（[<span style="color:#f24c27;font-weight:600">sanks的博客</span>](https://www.sanks-blog.com/)）
- 源码地址[github](https://github.com/Inception-entry/vue-tree-grid)，欢迎star。
- 参考资源[隔壁家的老黄](https://www.cnblogs.com/ychl/p/6075106.html)
- 参考资源[城池](https://juejin.cn/post/6844903645624926215)


## Build Setup

``` bash
# install dependencies
npm install

# serve with hot reload at localhost:8080
npm run dev

# build for production with minification
npm run build

# build for production and view the bundle analyzer report
npm run build --report
```

For a detailed explanation on how things work, check out the [guide](http://vuejs-templates.github.io/webpack/) and [docs for vue-loader](http://vuejs.github.io/vue-loader).
