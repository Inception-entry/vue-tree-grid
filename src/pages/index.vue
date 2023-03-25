<template>
  <div class="omc-common-css contains">
    <tree-grid
      ref="recTree"
      :list.sync="treeDataSource"
      @handlerFold="handlerFold"
      @handlerExpand="handlerExpand"
      :treeColumnList="treeColumns"
			:columnList="tableColumns"
      :tableListName="childrenAlias">
    >
      <template v-slot:mainAccount>
        <i class="tree-account">
          【主账号: SPgmdd】
        </i>
      </template>
      <template v-slot:treeOperate>
        <el-button type="text">添加子账号</el-button>
        <el-button type="text">修改</el-button>
        <el-button type="text">删除组织</el-button>
      </template>
      <template v-slot:extendTable="treeRowData">
        <el-table
          :data="handlerData(treeRowData.data.sub_account_list)"
          border
          lazy
          :max-height="470"
          class="show-border"
          style="width: 90%;"
          :style="treeRowData.data.children && treeRowData.data.children.length > 0 ? 'margin-left: 13px' : ''">
          <el-table-column
            v-for="column in tableColumns"
            :key="column.key"
            :prop="column.fieldName"
            :label="column.name"
            :min-width="column.minWidth"
            :show-overflow-tooltip="column.showTooltip"
          >
            <template slot-scope="scope">
              <span
                v-if="!column.slotName"
              >
              {{scope.row[column.fieldName]}}
              </span>
              <slot
                v-if="column.slotName"
                :name="column.slotName"
                :data="scope.row"
              >
                <el-button type="text">解除关联</el-button>
                <el-button type="text">变更组织</el-button>
              </slot>
            </template>
          </el-table-column>
        </el-table>
      </template>
    </tree-grid>
  </div>
</template>
<script>
import dataJson from './data.json'
import treeGrid from '@/components/pc/tree-grid.vue'
export default {
  data() {
    return {
      treeDataSource: dataJson,
      treeColumns: [ // 树表头
				{
          key: 1,
          name: '组织名称',
          fieldName: 'org_name',
          minWidth: 380,
          maxWidth: 500,
          mainAccountSlotName: 'mainAccount'
        },
        {
          key: 2,
          name: '子账号数量(个)',
          fieldName: 'sub_account_total',
          minWidth: 130,
          expandFunc: true
        },
        {
          key: 3,
          name: '操作',
          fieldName: 'operate',
          minWidth: 290,
          slotName: 'treeOperate',
        }
      ],
      tableColumns: [ // 内部表格表头
        {
          key: 1,
          name: '子账号名称',
          fieldName: 'sub_account_user_name',
          minWidth: 200,
          showTooltip: true,
        },
        {
          key: 2,
          name: '显示名',
          fieldName: 'sub_account_display_name',
          minWidth: 200,
          showTooltip: true,
        },
        {
          key: 3,
          name: '关联状态',
          fieldName: 'sub_account_relation_status',
          minWidth: 90,
          showTooltip: false,
        },
        {
          key: 4,
          name: '关联时间',
          fieldName: 'sub_account_relation_time',
          minWidth: 140,
          showTooltip: false,
        },
        {
          key: 5,
          name: '操作',
          fieldName: 'operate',
          minWidth: 160,
          showTooltip: false,
          slotName: 'tableOperate',
        }
      ],
      childrenAlias: 'sub_account_list',
    }
  },
  components: {
    treeGrid
  },
  methods: {
    // 深度优先遍历
    deepTraversal(node) {
      node.isExpand = false;
      if (node.children && node.children.length > 0) {
        let children = node.children;
        for (let i of children) {
          this.deepTraversal(i);
        }
      }
    },
    handlerFold(m) {
      console.log('展开/折叠')
      m.isFold = !m.isFold;
      if (!m.isFold) {
        this.deepTraversal(m);
      }
    },
    handlerExpand(m) {
      console.log('扩展/收起');
      m.isExpand = !m.isExpand;
    },
    handlerData(accountList) {
      // 缓存数据
      const cacheArray = [];
      // 插入数据总条数
      let total = accountList.length;
      // 一次插入 5 条
      let once = 5;
      // 每条记录的索引
      let index = 0;
      // 循环加载数据
      function loop(curTotal, curIndex){
          if(curTotal <= 0){
              return false;
          }
          // 每页多少条
          let pageCount = Math.min(curTotal , once);
          window.requestAnimationFrame(function(){
              for(let i = 0; i < pageCount; i++) {
                  cacheArray.push(accountList[curIndex + i]);
              }
              loop(curTotal - pageCount, curIndex + pageCount)
          })
      }
      loop(total, index);
      return cacheArray;
    }
  }
}
</script>

<style lang="less" scoped>
.contains {
  width: 1000px;
  margin: 30px auto;
}
/deep/ .el-button--text {
  padding: 0;
}
/deep/ .el-button--text + .el-button--text {
  position: relative;
  line-height: 14px;
  margin-left: 17px;
  &::before {
    position: absolute;
    content: "";
    height: 12px;
    border-left: 1px solid #E6E8EC;
    top: 50%;
    left: -10px;
    -webkit-transform: translate(0, -50%);
    transform: translate(0, -50%);
    pointer-events: none;
  }
}
.tree-account {
  color: #1db163;
  font-style: normal;
}
</style>
