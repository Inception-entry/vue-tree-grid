<template>
  <div :class="tdClass">
    <span
      class="before-line"
      v-if="root !== 0 && nodes !== 1"
      :style="{ left: model.bLeft + 'px' }"
    ></span>
    <table>
      <tr>
        <td :colspan="colSpan">
          <table>
            <tr class="level" :class="levelClass">
              <td class="td1">
                <div class="td-title">
                  <div>
                    <i
                      v-if="model.children && model.children.length > 0"
                      :class="
                        `zk-table--tree-icon zk-icon ${
                          model.isFold
                            ? 'zk-icon-minus-square-o zk-shield'
                            : 'zk-icon-plus-square-o'
                        }`
                      "
                      @click="handlerFold(model)"
                    />
                    <!--父表格行-->
                    <div class="tree-row">
                      <div
                        v-for="column in treeColumnList"
                        class="tree-column"
                        :style="treeColumnRender(column, model)"
                        :key="column.key"
                      >
                        <template>
                          <span
                            v-if="!column.slotName"
                            :style="{
                              width: column.expandFunc ? '40px' : 'auto'
                            }"
                            class="node-title"
                          >
                            {{ model[column.fieldName]
                            }}<slot
                              v-if="
                                column.mainAccountSlotName && model.level === 1
                              "
                              :name="column.mainAccountSlotName"
                              :data="model"
                            >
                            </slot>
                          </span>
                          <div
                            v-if="
                              column.expandFunc &&
                                model[tableListName] &&
                                model[tableListName].length > 0
                            "
                            class="zk-table__cell-inner zk-table--expand-inner"
                            :class="{
                              'zk-table--expanded-inner': model.isExpand
                            }"
                            @click="handlerExpand(model)"
                          >
                            <i class="zk-icon zk-icon-angle-right"></i>
                          </div>
                          <slot
                            v-if="column.slotName"
                            :name="column.slotName"
                            :data="model"
                          >
                          </slot>
                        </template>
                      </div>
                    </div>
                    <!--纯表格-->
                    <div
                      v-show="model.isExpand && model[tableListName].length > 0"
                      class="extend-table"
                      :style="tableRowRender"
                    >
                      <span
                        class="level-line"
                        v-show="
                          model.isFold &&
                            model.isExpand &&
                            model.children.length > 0
                        "
                      ></span>
                      <slot name="extendTable" :data="model"></slot>
                    </div>
                  </div>
                </div>
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>

    <div v-show="model.isFold" class="other-node" :class="otherNodeClass">
      <tree-unit
        v-for="(m, i) in model.children"
        :key="String('child_node' + i)"
        :num="i"
        :root="1"
        @handlerFold="handlerFold"
        @handlerExpand="handlerExpand"
        :nodes.sync="model[tableListName].length"
        :trees.sync="trees"
        :model="m"
        :treeColumnList="treeColumnList"
        :columnList="columnList"
        :tableListName="tableListName"
      >
        <template v-slot:extendTable="currentModel">
          <slot name="extendTable" :data="currentModel.data"></slot>
        </template>
        <template
          v-for="item in treeColumnList"
          v-slot:[item.slotName]="currentModel"
        >
          <slot :name="item.slotName" :data="currentModel.data"> </slot>
        </template>
        <template
          v-for="item in treeColumnList"
          v-slot:[item.mainAccountSlotName]="currentModel"
        >
          <slot :name="item.mainAccountSlotName" :data="currentModel.data">
          </slot>
        </template>
      </tree-unit>
    </div>
  </div>
</template>

<script>
export default {
  name: "treeUnit",
  props: [
    "model",
    "num",
    "nodes",
    "root",
    "trees",
    "treeColumnList",
    "columnList",
    "tableListName"
  ],
  data() {
    return {
      parentNodeModel: null
    };
  },
  computed: {
    colSpan() {
      return this.root === 0 ? "" : 6;
    },
    tdClass() {
      return this.root === 0 ? "td-border" : "not-border";
    },
    levelClass() {
      return this.model ? "level-" + this.model.level : "";
    },
    childNodeClass() {
      return this.root === 0 ? "" : "child-node";
    },
    otherNodeClass() {
      return this.model ? "other-node-" + this.model.level : "";
    },
    tableRowRender() {
      let btnBackground = {
        "padding-top": "20px",
        "padding-bottom": "20px",
        "margin-left": `${-54 + (this.model.level - 1) * (-15)}px`,
        "padding-left": `${65 + (this.model.level - 1) * 15}px`,
        "background-color": "#f4f6fa"
      };
      return btnBackground;
    }
  },
  watch: {
    // 'model': {
    // 	handler() {
    // 		console.log('对象变化', this.model.isFold)
    // 	},
    // 	deep: true
    // }
  },
  methods: {
    columnRender(column, model) {
      if (column.key === 1) {
        if (model.children && model.children.length > 0) {
          return "26px";
        } else {
          return "12px";
        }
      } else {
        return "0px";
      }
    },
    treeColumnRender(column, model) {
      return {
        "flex-basis":
          column.key !== 2
            ? column.minWidth - 14 * (model.level - 1) + "px"
            : column.minWidth + 13 * (model.level - 1) + "px",
        "min-width":
          column.key !== 2
            ? column.minWidth - 14 * (model.level - 1) + "px"
            : column.minWidth + 13 * (model.level - 1) + "px",
        display: column.expandFunc ? "flex" : "inline-block",
        "padding-left": this.columnRender(column, model),
        "padding-right": column.key === 3 ? "30px" : "0",
        "text-align": column.key === 3 ? "right" : "left",
        "text-overflow": "ellipsis"
      };
    },
    getParentNode(m) {
      // 查找点击的子节点
      const recurFunc = (data, list) => {
        data.forEach(l => {
          if (l.id === m.id) this.parentNodeModel = list;
          if (l.children) {
            recurFunc(l.children, l);
          }
        });
      };
      recurFunc(this.trees, this.trees);
    },
    handlerFold(m) {
      this.$emit("handlerFold", m);
    },
    handlerExpand(m) {
      this.$emit("handlerExpand", m);
    }
  },
  filters: {
    formatDate: function(date) {
      // 后期自己格式化
      return date; //Utility.formatDate(date, 'yyyy/MM/dd')
    }
  }
};
</script>
<style lang="less">
.tree-row {
  position: relative;
  display: flex;
  justify-content: space-between;
  line-height: 17px;
  &:hover {
    background: #f4f6fa;
  }
  .tree-column {
    position: relative;
    min-width: 12px;
    overflow: hidden;
    padding: 11px 10px;
    word-wrap: break-word;
    word-break: break-all;
    box-sizing: border-box;
    & > span {
      /* display: table; */
      height: 100%;
    }
    .node-title {
      white-space: nowrap;
    }
  }
}
.zk-table--tree-icon {
  position: absolute;
  width: 18px;
  height: 18px;
  left: 0;
  top: 0;
  z-index: 4;
  margin-right: 6px;
  margin-left: 2px;
  cursor: pointer;
  color: #333333;
  font-size: 18px;
  &.zk-shield::after {
    content: "";
    position: absolute;
    top: 21px;
    left: 4px;
    width: 10px;
    height: 5px;
    background-color: #ffffff;
    z-index: 4;
  }
}

.zk-icon-simple-person {
  display: inline-block;
  width: 20px;
  height: 20px;
  background: url("./icon/Personal.svg") no-repeat center center;
  background-size: 100% 100%;
  vertical-align: middle;
}

.zk-icon-angle-right:before {
  font-size: 20px;
}

.zk-table--expand-inner {
  height: 17px;
  text-align: center;
  cursor: pointer;
  transition: transform 0.2s ease-in-out;
  display: inline-block;
  transform: rotate(90deg);
  vertical-align: bottom;
  .zk-icon {
    display: block;
    font-size: 20px;
  }
}

.zk-table--expanded-inner {
  transform: rotate(-90deg);
}

.extend-table {
  .level-line {
    position: absolute;
    left: 11px;
    top: 26px;
    width: 1px;
    height: 96%;
    background-color: #a3a5a9;
    z-index: 999;
  }
}
</style>
