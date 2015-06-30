package com.sathish.learning.nettykafka;

/* IMPORTANT: class must not be public. */

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Scanner;

class smallfactorial {
	static int totalEntries = 0;
	static BigInteger factorialNum = new BigInteger("1");

	public static void main(String args[]) throws Exception {

		Scanner scan = new Scanner(System.in);
		totalEntries = scan.nextInt();

		for (int i = 0; i < totalEntries; i++) {
			int facFindNum = scan.nextInt();
			// factorialNum = javaSpecific(facFindNum);
			List<Integer> finalArray = generalToAllLanguageConcept(facFindNum);
			System.out.println(finalArray.size());

			System.out.print("out put: ");
			for (int j = finalArray.size(); j > 0; j--) {
				System.out.print(finalArray.get(j - 1));
			}
			System.out.println();
		}
		// System.out.println(factorialNum);
	}

	public static List<Integer> generalToAllLanguageConcept(int facFindNum) {
		List<Integer> tempArray = new ArrayList<Integer>(Arrays.asList(1));// =
		int temp = 0;
		System.out.println("tempArray.length: " + tempArray.get(0));
		for (int i = 1; i <= facFindNum; i++) {
			tempArray = multiply(tempArray, i);
		}
		return tempArray;
	}

	public static List<Integer> multiply(List<Integer> tempArray, int multiValue) {
		List<Integer> newArray = new ArrayList<Integer>();
		System.out.println("multiValue : " + multiValue);
		int temp = 0;
		for (int i = 0; i < tempArray.size(); i++) {
			int tempValue = (tempArray.get(i) * multiValue) + temp;
			temp = tempValue;
			System.out.println(i + "::tempValue : " + temp);
			if (temp > 10) {
				temp = (tempValue / 10);
				System.out
						.println("Temp here in moduelo : " + (tempValue % 10));
				newArray.add((tempValue % 10));
			} else {
				System.out.println("Temp here in direct addition : " + temp);
				newArray.add(temp);
				temp = 0;
			}
		}
		System.out.println("LAST :::Temp here in moduelo : " + temp);
		while (temp > 0) {

			// System.out.println(i + "::temp : " + temp);
			if (temp > 10) {
				temp = (temp / 10);
				System.out.println("OUTSIDE::Temp here in moduelo : "
						+ (temp % 10));
				newArray.add((temp % 10));
			} else {
				System.out.println("OUTSIDE::Temp direct addition : " + temp);
				newArray.add(temp);
				temp = 0;
			}
		}
		return newArray;
	}

//	public List<Integer> addValueToArrayList(int temp, List<Integer> newArray){
//		
//	}
	@SuppressWarnings("null")
	public static int[] convertArray(int value) {
		int temp = 0, i = 0;
		int[] tempArray = null;
		while (true) {
			tempArray[i] = (value % 10);
			temp = (value / 10);
			System.out.println(value % 10);
			value = temp;
			i++;
			if (temp == 0)
				break;
		}
		return tempArray;
	}

	public static BigInteger javaSpecific(int facFindNum) {

		BigInteger factorialNumTemp = new BigInteger("1");
		for (int j = 1; j <= facFindNum; j++) {
			factorialNumTemp = factorialNumTemp
					.multiply(new BigInteger(j + ""));
		}

		return factorialNumTemp;
	}

}
