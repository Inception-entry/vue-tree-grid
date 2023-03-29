# 基于vue.js实现树形表格的封装（vue-tree-grid）

## 前言
> 由于公司产品（基于vue.js）需要，要实现一个[树形表格](https://github.com/Inception-entry/vue-tree-grid)的功能，百度、google找了一通，并没有发现很靠谱的，也不是很灵活。所以就用vue自己写了一个，还望大家多多指教。
- <span style="color:#f24c27;font-weight:600">注意：鉴于本组件包含样式和布局等，而且对于需要此组件的你来说，需要定制化调整，故而没有打包成npm下载可直接引入的形式，因为没有太大的实际意义，人生有限，不要把时间浪费在无意义的事情上。</span>
#### 主要技术点：`vue子组件的递归实现及相关样式的实现`

## 路由讲解
- 根路由：拓展的内部表格数据过多, 是时间分片方式处理的
- /virtual: 拓展的内部表格数据过多, 是虚拟列表方式处理的(强烈建议用此方式)

## 树形表格实现
- 效果图([Demo](https://inception-entry.github.io/dist/#/))![效果图](https://inception-entry.github.io/dist/20230328_202702.gif)
- 主要代码
> index.vue页面实现业务逻辑代码，比如树表格上面的一些操作按钮的实现及数据获取。
>
``` html
<template>
  <div class="common-css contains">
    <tree-grid
      ref="recTree"
      :list.sync="treeDataSource"
      @handlerFold="handlerFold"
      @handlerExpand="handlerExpand"
      :treeColumnList="treeColumns"
			:columnList="tableColumns"
      :tableListName="childrenAlias">
      ...代码省略...
    </tree-grid>
  </div>
</template>
<script>
import dataJson from './data1.json';
import treeGrid from '@/components/tree-grid.vue';
export default {
  data() {
    return {
      treeDataSource: dataJson,
      treeColumns: [], // 树表头
      tableColumns: [],// 内部表格表头
      childrenAlias: 'sub_account_list',
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
					<th
            :class="`th${index + 1}`"
            :style="treeHeaderRender(item, index, treeColumnList)"
            v-for="(item, index) in treeColumnList"
            :key="item.key"
          >
            {{ item.name }}
          </th>
				</tr>
			</table>
		</div>
		<div id="scrollWrap" class="tree-wrap">
			<div class="tree-body">
				<table v-if="treeDataSource.length > 0">
          <tbody>
            <tr>
              <td>
                <tree-unit
                  v-for="(model, i) in treeDataSource"
                  :key="'root_node_' + i"
                  :root="0"
                  :num="i"
                  @handlerFold="handlerFold"
                  @handlerExpand="handlerExpand"
                  :nodes="treeDataSource.length"
                  :trees.sync="treeDataSource"
                  :model="model"
                  :treeColumnList="treeColumnList"
                  :columnList="columnList"
                  :tableListName="tableListName">
                ...代码省略...
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
