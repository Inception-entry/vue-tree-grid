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
        <InfiniteScrollTable
          ref="ref_infinite_table"
          :scrollData="treeRowData.data.sub_account_list"
          :getMoreData="getMoreDataFn"
          :loadConfig="loadConfig"
          :showTopBtn="false"
          :showBottomBar="false"
          :loadImmediate="true"
          @setTableData="setTableDataFn(arguments, treeRowData.data)"
        >
          <el-table
            :data="treeRowData.data.tableData"
            border
            lazy
            :height="treeRowData.data.tableData.length > 10 ? 432 : treeRowData.data.tableData.length * 40 + 32"
            :max-height="432"
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
        </InfiniteScrollTable>
      </template>
    </tree-grid>
  </div>
</template>
<script>
import dataJson from './data2.json'
import treeGrid from '@/components/pc/tree-grid.vue'
import InfiniteScrollTable from '@/components/pc/InfiniteScrollTableWrapper.vue';
export default {
  data() {
    return {
      treeDataSource: [],
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
      loadConfig: {
        loadingText: '加载中', // 加载时提示文字
        verText: '', // 所有数据加载完毕后显示文字
        totalCount: 0,
        itemHeight: 40, // 每一行数据的最小高度，不传默认40
        distance: 40, // 滚动条距离底部并触发滚动加载的距离 不传 则默认为20
      },
      scrollData: [],
    }
  },
  components: {
    treeGrid,
    InfiniteScrollTable
  },
  methods: {
    // 深度优先遍历，为节点增加tableData
    deepTraversal2(node) {
      node.tableData = node.sub_account_list.slice(0, 13);
      if (node.children && node.children.length > 0) {
        let children = node.children;
        for (let i of children) {
          this.deepTraversal2(i);
        }
      }
      return node;
    },
    // 为虚拟列表新增tableData字段，并注入初始数据
    virtualList() {
      let arr = dataJson.map(item => {
        return this.deepTraversal2(item);
      });
      return arr;
    },
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
    async getMoreDataFn() {
      this.$refs.ref_infinite_table.loadStart(); // 加载前调用 loadStart
      this.loadConfig.totalCount = 2000; // 注意设置后端共有多少数据，以便判断结束
      this.$refs.ref_infinite_table.loadEnd(); // 加载后调用 loadEnd
    },
    setTableDataFn(arr, parentObj) {
      parentObj.tableData = arr[0];
    },
  },
  created() {
    this.treeDataSource = this.virtualList();
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
