//First of all, make sure the ngdbc.jar has been added to CLASSPATH
//Otherwise, specify it in the --classpath argument

import java.sql.*;

public class jdbcConn {
   public static void main(String[] argv) {
      Connection connection = null;
      try {                  
         connection = DriverManager.getConnection(
            "jdbc:sap://myhdb:30715/?autocommit=false",username,pswd);                  
      } catch (SQLException e) {
         System.err.println("Connection Failed. User/Passwd Error?");
         e.printStackTrace();
         return;
      }
      if (connection != null) {
         try {
            System.out.println("Connection to HANA successful!");
            //Statement stmt = connection.createStatement();
            PreparedStatement pstmt = connection.prepareStatement( "select * from USERS where user_name = ?" );
            pstmt.setString(1, "SYSTEM");
            //ResultSet resultSet = stmt.executeQuery("Select 'hello world' from dummy");
            ResultSet res = pstmt.executeQuery(); 
            //resultSet.next();
            String outp = res.getString(1);
            System.out.println(outp);
       } catch (SQLException e) {
          System.err.println("Query failed!");
       }
     }
   }
}
