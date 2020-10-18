



# GUI编程

## 1. 简介

- Swing  
- AWT

## 2. AWT

### 2.1 AWT介绍

1. 包含了很多类和接口！ GUI：

2. 元素：窗口，按钮，文本框

3. java.awt

   ```java
   public class TestFrame {
       public static void main(String[] args) {
           //Frame
           Frame frame = new Frame("这是我的第一个Java图形化窗口");
           //需要可见
           frame.setVisible(true);
           //设置大小
           frame.setSize(500,500);
           //设置颜色
           frame.setBackground(new Color(246, 4, 125));
           //设置大小不可变
           frame.setResizable(false);
           //设置初始化位置
           frame.setLocation(200,200);
       }
   }
   ```

   ```java
   //窗口Frame
   public class Multiple {
       public static void main(String[] args) {
           MyFrame myFrame1 = new MyFrame(100,100,200,200);
           MyFrame myFrame2 = new MyFrame(100,300,200,200);
           MyFrame myFrame3 = new MyFrame(300,100,200,200);
           MyFrame myFrame4 = new MyFrame(300,300,200,200);
       }
   }
   class  MyFrame extends Frame {
       static int id = 1;
       public MyFrame(int x, int y, int width, int height) {
           super("窗口编号为：" + (++id));
           setBounds(x, y, width, height);
           setVisible(true);
           setResizable(false);
           setBackground(Color.BLACK);
       }
   }
   ```

   ```java
   //面板
   public class MyPanel {
       public static void main(String[] args) {
           Frame frame = new Frame();
           //panel 一个空间，但不能单独存在
           //面板
           Panel panel = new Panel();
           //设备布局
           frame.setLayout(null);
           //frame坐标
           frame.setBounds(300, 300, 500, 500);
           frame.setBackground(new Color(2, 3, 5));
           //Panel坐标，相对于frame
           panel.setBounds(50, 50, 400, 400);
           panel.setBackground(new Color(34, 200, 5));
           frame.add(panel);
           frame.setVisible(true);
           //监听事件，监听窗口
           frame.addWindowListener(new WindowAdapter() {
               //关闭的时候做的事情
               @Override
               public void windowClosing(WindowEvent e) {
                   System.exit(0);
               }
           });
       }
   }
   ```

   ```java
   
   ```

#### 2.2布局管理器

1. 流式布局

   ```java
   public class Layout {
       public static void main(String[] args) {
           System.out.println();
           Frame frame = new Frame();
           //组件按钮
           Button button1 = new Button("第一个按钮");
           Button button2 = new Button("第一个按钮");
           Button button3 = new Button("第一个按钮");
           //设置为流式布局
           frame.setLayout(new FlowLayout());
           //
           frame.setSize(200,200);
           frame.add(button1);
           frame.add(button2);
           frame.add(button3);
           frame.setVisible(true);
       }
   }
   ```

2. 东南西比中

   ```java
   public class Position {
       public static void main(String[] args) {
           Frame frame = new Frame();
           Button east = new Button("East");
           Button west = new Button("West");
           Button south = new Button("South");
           Button north = new Button("North");
           Button center = new Button("Center");
           //
           frame.add(east,BorderLayout.EAST);
           frame.add(west,BorderLayout.WEST);
           frame.add(south,BorderLayout.SOUTH);
           frame.add(north,BorderLayout.NORTH);
           frame.add(center,BorderLayout.CENTER);
   
           frame.setSize(200,200);
           frame.setVisible(true);
   
       }
   }
   ```

3. 表格布局

   ```java
   public class TestGridLayout {
       public static void main(String[] args) {
           Frame frame = new Frame();
           Button btn1 = new Button("btn1");
           Button btn2 = new Button("btn2");
           Button btn3 = new Button("btn3");
           Button btn4 = new Button("btn4");
           Button btn5 = new Button("btn5");
           Button btn6 = new Button("btn6");
           //GridLayout方法设置行列
           frame.setLayout(new GridLayout(3,2));
           frame.add(btn1);
           frame.add(btn2);
           frame.add(btn3);
           frame.add(btn4);
           frame.add(btn5);
           frame.add(btn6);
           frame.pack();
           frame.setVisible(true);
       }
   }
   ```

```java
public class task {
    public static void main(String[] args) {
        Frame frame = new Frame();
        frame.setBounds(300, 300, 500, 500);
        //frame.setBackground(new Color(2, 3, 5));
        frame.setVisible(true);
        frame.setLayout(new GridLayout(2,1));
        Panel p1 = new Panel(new BorderLayout());
        Panel p2 = new Panel(new GridLayout(2,1));
        Panel p3 = new Panel(new BorderLayout());
        Panel p4 = new Panel(new GridLayout(2,2));
        p1.add(new Button("左"),BorderLayout.EAST);
        p1.add(new Button("右"),BorderLayout.WEST);
        p2.add(new Button("上"));
        p2.add(new Button("下"));
        p1.add(p2,BorderLayout.CENTER);
        p3.add(new Button("east"),BorderLayout.EAST);
        p3.add(new Button("west"),BorderLayout.WEST);
        p4.add(new Button("east"));
        p4.add(new Button("east"));
        p4.add(new Button("east"));
        p4.add(new Button("west"));
        p3.add(p4,BorderLayout.CENTER);
        frame.add(p1);
        frame.add(p3);
    }
}
```



