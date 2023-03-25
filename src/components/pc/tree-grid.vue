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
                  :tableListName="tableListName"
                >
                  <template
                    v-for="item in treeColumnList"
                    v-slot:[item.slotName]="currentModel"
                  >
                    <slot :name="item.slotName" :data="currentModel.data">
                    </slot>
                  </template>
                  <template
                    v-for="item in treeColumnList"
                    v-slot:[item.mainAccountSlotName]="currentModel"
                  >
                    <slot
                      :name="item.mainAccountSlotName"
                      :data="currentModel.data"
                    >
                    </slot>
                  </template>
                  <template v-slot:extendTable="currentModel">
                    <slot name="extendTable" :data="currentModel.data"> </slot>
                  </template>
                </tree-unit>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script>
import treeUnit from './tree-unit.vue';
	export default {
		name: 'treeGrid',
		props: ['list', 'treeColumnList', 'columnList', 'tableListName'],
		data() {
			return {
				treeDataSource: [],
			}
		},

		watch: {
			'list': {
				handler() {
					this.initTreeData()
				},
				deep: true
			},
		},
		computed: {
		},
		methods: {
			treeHeaderRender(item, index, list) {
				if(index !== list.length - 1) {
					return {
						'flex-basis': item.minWidth + 'px' || '100px',
						'min-width': item.minWidth + 'px' || '100px',
						'max-width': item.maxWidth + 'px' || '500px',
					}
				} else {
					return {
						'flex-basis': item.minWidth + 'px' || '100px',
						'min-width': item.minWidth + 'px' || '100px',
						'max-width': item.maxWidth + 'px' || '500px',
						'padding-left': '80px'
					}
				}
			},
			initTreeData() {
				console.log('处理前的:', JSON.parse(JSON.stringify(this.list)))
				// 这里一定要转化，要不然他们的值监听不到变化
				let tempData = JSON.parse(JSON.stringify(this.list))
				let reduceDataFunc = (data, level) => {
					data.map((m, i) => {
						m.isFold = true
						m.isExpand = true
						m.children = m.children || []
						m.level = level
						m.bLeft = level === 1 ? 65 : (level - 2) * 14 + 65
						m.Experience = m.Experience || '无'
						if (m.children.length > 0) {
							reduceDataFunc(m.children, level + 1)
						}
					})
				}
				reduceDataFunc(tempData, 1)
				console.log('处理后的:', tempData)
				this.treeDataSource = tempData
			},
			getMore() {
				alert('滚动到底部加载更多')
				// 滚动到最后
				$('#scrollWrap').mCustomScrollbar('scrollTo', 'top', {
					scrollInertia: 0
				})
      },
      // 展开
      handlerFold(m) {
        this.$emit('handlerFold', m)
      },
			// 拓展
			handlerExpand(m) {
				this.$emit('handlerExpand', m)
			}
		},
		components: {
			'tree-unit': treeUnit
		},
		mounted() {
			const vm = this
			vm.$nextTick(() => {
				vm.initTreeData()
			})
		}
	}
</script>
<style lang="less" src="./Table.less"></style>
